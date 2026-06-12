# [008] Bug Reports inbox & detail (resolve/delete)

**Type:** AFK
**Priority:** P2
**Blocked by:** 002, 004

---

## What to build

The `bugReports` pill content (shown only when a project's `hasBugReports` is true): an inbox of
crash/error reports filed by an app's clients, plus a detail view.

`BugReport` entity and `BugSeverity` enum: `info`, `warning`, `error`, `critical`.

Modules:

- `BugReportsRepository` (abstract) + HTTP implementation:
  - `GET /api/v1/projects/{projectKey}/bug-reports`
  - `PATCH /api/v1/projects/{projectKey}/bug-reports/{id}` — `{ resolved }`
  - `DELETE /api/v1/projects/{projectKey}/bug-reports/{id}`
- `BugReportsController extends StreamState<AsyncState<List<BugReport>>>` with `load(projectKey)`,
  `resolve(id)`, `delete(id)`.

UI (per `screen-bugs.jsx`):

- `BugInboxScreen`: severity filter pills + list of reports.
- `BugDetailScreen`: full message, stack trace, source, timestamp, resolve/delete actions.

---

## Acceptance criteria

- [ ] For a project with `hasBugReports: true`, the `bugReports` pill shows the inbox, filterable by
      severity.
- [ ] Opening a report shows its full message, stack trace, source, and timestamp.
- [ ] Resolving/deleting a report calls the corresponding endpoint and updates the list.
- [ ] For a project with `hasBugReports: false`, no `bugReports` pill is shown (covered by 004, verified
      here end-to-end).

---

## Tests required

Yes — `BugReportsController` unit tests with `FakeBugReportsRepository`: load/filter/resolve/delete flows.

---

## Notes

- Full end-to-end verification requires the reworked backend's bug-report endpoints to exist; this slice's
  automated tests use fakes.
- The "Convert to issue" action visible in this screen's design is wired up in slice 011.

---

## Log

- Implementation found complete from a prior session: `BugReport`/`BugSeverity`, `BugReportsRepository` +
  HTTP impl (`BugReportsDatasource`/`BugReportsRepositoryImpl`), `BugReportsController` (load/resolve/delete/
  filteredBySeverity), and `BugInboxSection`/`BugDetailSection` UI wired into the shell's `bugReports` pill
  (only rendered when `project.hasBugReports`).
- Verified: `flutter analyze` clean, `flutter test` passes including `BugReportsController` unit tests with
  `FakeBugReportsRepository` covering load/resolve/delete/filteredBySeverity. All acceptance criteria met.
