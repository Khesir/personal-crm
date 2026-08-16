# 4. `.avyn/` project folder is authoritative for name/settings; SharedPreferences becomes a visit-refreshed cache

## Status

Accepted

## Context

Today a `Project`'s entire identity — `id`, `name`, `localPath`, `projectKey` — lives only in `SharedPreferences`, with nothing written to disk inside the project folder itself. We're adding per-project metadata (display name, an icon/image, and room for future settings) and want it to be:

- **Portable** — move, copy, or share a project folder and its identity (name, icon, settings) travels with it, the way `.git/config` does.
- **Recoverable** — if `SharedPreferences` is ever lost or corrupted, the project registry can in principle be rebuilt by re-scanning known folders for `.avyn/project.json`.

A naive implementation would read every registered project's `.avyn/project.json` from disk on every project-list load (e.g. every time the rail renders), which is simple but adds avoidable disk I/O and failure surface (slow/network drives, a project folder temporarily unavailable) to a UI element that needs to paint instantly at startup.

## Decision

`.avyn/project.json` (plus an optional `.avyn/icon.<ext>`) is the authoritative source for a project's name and settings — editing it, or moving the folder elsewhere with it intact, is a legitimate way to change or carry a project's identity. It is always auto-created: immediately on both "create new project" and "register existing folder" registration, and retroactively the first time an already-registered project (predating this feature) is loaded and found to be missing it. This differs deliberately from the `issues/` folder's cautious "never silently write, show an explicit Initialize action" policy (see issue 006) — `.avyn/` is app-owned infrastructure the app cannot function without, not user content.

`SharedPreferences` is demoted to a cache: it stores each project's `id`, `localPath`, and last-known `name` (and icon path once that lands), letting the project rail render instantly without disk reads. This cache is refreshed from `.avyn/project.json` only when that specific project is visited (selected as the working project) — not on every app launch, not on a timer, not for every project whenever any one of them changes. An unvisited project's cached name can therefore be briefly stale if its `.avyn/project.json` was edited externally, until it's next selected.

## Consequences

### Positive

- Project folders are self-describing and portable; the app's own registry is a rebuildable cache, not the only copy of a project's identity.
- The rail stays fast — startup and re-render never block on filesystem reads across every registered project.

### Negative / Risks

- An externally-edited project name won't show in the rail until that project is next selected — a deliberate staleness window, not a bug, but worth remembering when debugging "why doesn't the rail show my rename."
- `SharedPreferences`'s stored shape changes (no longer the full `Project`, just an index-plus-cache), which needs a migration path for existing installs' data rather than a clean-slate assumption.

## Alternatives Considered

- **Always read `.avyn/project.json` fresh on every project-list load** — simpler mental model (no staleness window at all), rejected as unnecessary disk I/O on a UI path that should be instant, especially once icon files are involved.
- **Keep SharedPreferences authoritative, `.avyn/` as a regenerated/overwritten mirror** — rejected because it defeats the portability goal: a copied/shared project folder wouldn't carry its real name if the app can overwrite `.avyn/` from its own cache at will.
