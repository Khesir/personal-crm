# 1. Patch local Flutter SDK to support VS2026 CMake generator on Windows

## Status

Accepted

## Context

Running `flutter run -d windows` / `flutter build windows` on this machine fails
during the CMake configure step:

```
CMake Error at CMakeLists.txt:3 (project):
  Generator

    Visual Studio 16 2019

  could not find any instance of Visual Studio.
```

Investigation found:

- The only Visual Studio installation on this machine is **Visual Studio
  Community 2026 Insiders (v18)**. `flutter doctor` already flags this as a
  pre-release version that "may not be supported by Flutter yet."
- Flutter 3.35.7's tooling
  (`flutter_tools/lib/src/windows/visual_studio.dart`, `cmakeGenerator`
  getter) maps the detected Visual Studio major version to a CMake
  `-G` generator string, but only has an explicit case for major version 17
  (VS 2022 -> `"Visual Studio 17 2022"`). Every other version, including 18
  (VS 2026), falls through to a hardcoded default of
  `"Visual Studio 16 2019"`, which doesn't exist on this machine.
- The CMake toolchain bundled with VS 2026 Insiders (cmake 4.2.3-msvc3)
  already supports a `"Visual Studio 18 2026"` generator
  (`cmake -G` lists it).
- A second-order issue: once the generator string is corrected, a stale
  `build/windows/x64/CMakeCache.txt` (written by the earlier failing build,
  or generated under a different generator) causes CMake to refuse to
  reconfigure ("generator ... does not match the generator used
  previously"). This requires deleting `build/windows` once after the fix.

## Decision

Apply a local patch to the globally-installed Flutter SDK rather than
installing Visual Studio 2022:

1. Edit `C:\Program Files\flutter\packages\flutter_tools\lib\src\windows\visual_studio.dart`,
   adding a case to `cmakeGenerator`:

   ```dart
   return switch (_majorVersion) {
     18 => 'Visual Studio 18 2026',
     17 => 'Visual Studio 17 2022',
     _ => 'Visual Studio 16 2019',
   };
   ```

2. Force `flutter_tools` to recompile so the edit takes effect, by deleting
   `bin\cache\flutter_tools.snapshot` and `bin\cache\flutter_tools.stamp`.
   (Flutter's cache-invalidation only checks the framework's git revision and
   `pubspec.yaml`/`pubspec.lock` timestamps -- it does not detect direct edits
   to `flutter_tools` source files.)

3. Delete the project's `build/windows` directory once, so CMake regenerates
   its cache using the corrected generator instead of erroring on a mismatch
   with a previously-cached generator.

## Consequences

### Positive

- `flutter run -d windows` / `flutter build windows` work on this machine
  without installing an additional, several-GB Visual Studio 2022 toolchain.

### Negative / Risks

- This patches the **global Flutter SDK install**
  (`C:\Program Files\flutter`), not anything inside this repository. It is
  not version-controlled and will not apply automatically:
  - on other developers' machines,
  - in CI,
  - or after `flutter upgrade` / `flutter channel` switches, which refetch
    `flutter_tools` sources and will likely overwrite this patch (requiring
    it to be reapplied, then the snapshot deleted again).
- Visual Studio 2026 is still pre-release ("Insiders"). Its toolchain/CMake
  generator behavior could change before GA, possibly invalidating the
  `"Visual Studio 18 2026"` mapping.
- Anyone else building this project's Windows target needs either this same
  SDK patch (with only VS 2026 installed) or a standard VS 2022 install
  (officially supported by this Flutter version).

## Alternatives Considered

- **Install Visual Studio 2022 Community.** Officially supported by Flutter
  3.35.7 out of the box, no SDK patching required, and not affected by
  `flutter upgrade`. Rejected for now due to the size/time of the install;
  this remains the recommended long-term fix and should be revisited.
- **Wait for an upstream Flutter release with native VS 2026 support.**
  Blocks local Windows development indefinitely; rejected.

## Follow-ups

- Track upstream Flutter support for Visual Studio 2026
  (`visual_studio.dart` `cmakeGenerator`) and drop this local patch once a
  stable Flutter release handles major version 18 natively.
- If `flutter upgrade` is run, re-check `flutter doctor -v` and re-run
  `flutter build windows`; if the CMake-16-2019 error reappears, reapply
  steps 1-3 above.
- Consider installing Visual Studio 2022 Community as the durable fix.
