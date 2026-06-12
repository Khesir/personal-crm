# 2. Separate dev/prod local data and prevent same-build multi-instance

## Status

Accepted

## Context

The app persists local data (project registry, chat conversations, env
overrides) via `shared_preferences`, all under fixed keys (`settings.projects`,
`home.conversations`, `env_override_*`).

Running a debug build (`flutter run -d windows`) and a release build side by
side reads and writes the same SharedPreferences-backed storage, so:

- A dev session can overwrite data the prod build relies on, and vice versa.
- Two instances of the same build writing to the same storage concurrently
  can corrupt the project registry or chat history (last write wins).

The sibling `time-track` project solves both problems:

- Local cache (Hive) is initialized into a `dev` subdirectory in debug builds
  (`Hive.initFlutter(kDebugMode ? 'dev' : null)`), keeping dev and prod data
  on disk separate.
- A `SingleInstanceService` binds a loopback TCP socket on a build-specific
  port. A second launch of the same build fails to bind, notifies the first
  instance (which focuses its window), and exits.

`crm` has no Hive dependency — all local persistence is SharedPreferences
key/value pairs — so the separation needs to be done by namespacing keys
rather than by directory.

## Decision

1. Add `lib/core/config/data_namespace.dart`:

   ```dart
   const String kDataNamespace = kDebugMode ? 'dev' : 'prod';
   ```

2. Prefix every SharedPreferences key used for app data with
   `$kDataNamespace.`:
   - `kProjectsPrefsKey` → `'$kDataNamespace.settings.projects'`
   - `kChatConversationsPrefsKey` → `'$kDataNamespace.home.conversations'`
   - `kSettingsPrefix` (env overrides) → `'$kDataNamespace.env_override_'`

   Debug and release builds now read/write disjoint keys in the same
   SharedPreferences store, so they can never clobber each other's data.

3. Add `lib/core/window/single_instance_service.dart`, ported from
   `time-track`'s `SingleInstanceService`, using ports distinct from
   `time-track`'s (51823/51824) to avoid collisions if both apps run at once:
   - dev: `51934`
   - prod: `51933`

4. Wire it into `main.dart`: after the window is created, `acquire()` the
   lock. If acquisition fails (another instance of the same build is already
   running), close the window and exit immediately. On success, register
   `onSecondInstanceLaunched` to restore/show/focus the existing window.

5. Debug builds show `Codex (Dev)` as the window title so a dev and prod
   window can be told apart at a glance.

## Consequences

### Positive

- A dev build and a prod build can run simultaneously without corrupting
  each other's project registry, chat history, or env overrides.
- Launching a second instance of the same build focuses the existing window
  instead of spawning a duplicate with its own (eventually conflicting)
  SharedPreferences writes.

### Negative / Risks

- Existing dev users' previously-saved data (under the old unprefixed keys)
  becomes inaccessible after this change — there is no migration, so local
  project registries / chat history / env overrides start empty again. This
  is acceptable for the current single-developer, pre-release stage of the
  app.
- The lock ports (51933/51934) are hardcoded; if another local service binds
  the same loopback port, instance detection silently fails (falls through to
  allowing a second instance).

## Alternatives Considered

- **Separate SharedPreferences "files" per build** — not supported by the
  `shared_preferences` plugin on desktop without additional packages; key
  prefixing achieves the same isolation with no new dependencies.
- **Use a single instance lock without data namespacing** — would still allow
  one dev + one prod instance to run, but they'd share storage and could
  overwrite each other's data, defeating the purpose.
