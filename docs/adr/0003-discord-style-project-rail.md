# 3. Replace the Projects tab + sidebar list with a flat project rail

## Status

Accepted

## Context

Today the shell has two nested navigation levels (`AppRail` → `AppSidebar`):
`AppRail` is a fixed two-icon strip (Projects, Settings); selecting the
Projects icon shows `AppSidebar`'s list of registered projects, and only
selecting a project from *that* list makes it the working project and shows
its board in the content area. Registering a new project is even further
removed — it lives inside Settings > Projects, behind an "Add Project"
dialog with a freely-typable path field.

This is three clicks/steps to get from "app is open" to "I'm looking at a
project's board," and project creation/registration is disconnected from
where projects are actually used. We're adding a proper create-project flow
(new folder vs. register existing folder, with persistent tracking) and
want project switching to be immediate from anywhere in the app, not gated
behind a dedicated tab.

## Decision

Collapse the two-level structure for projects into one: `AppRail` becomes a
Discord-server-list-style rail — every registered project renders as an
icon (initials in a colored circle), selecting one directly sets it as the
working project and renders its board full-width in the content area, no
intermediate sidebar list. A create/register action (`+`) sits at the
bottom of the project icons, with the Settings gear pinned below that.
Settings keeps its own second sidebar column (Projects/About sections)
unchanged — full project management (rename/remove) still lives there,
duplicated only by a lightweight right-click menu on rail icons for
rename/remove/reveal-in-explorer.

The "Projects" `AppTab` and its sidebar list are removed; `AppSidebar` is
now Settings-only.

## Consequences

### Positive

- Switching projects is one click from anywhere, matching the mental model
  of "projects are the primary unit of this app," not a buried list.
- Project creation/registration sits next to where projects are used
  instead of only in Settings.

### Negative / Risks

- No room left in the rail for a text label per project — icons are
  initials-only, disambiguated by tooltip. Many projects will require
  scrolling the rail.
- There's no longer a dedicated "browse all projects" screen outside
  Settings; if a future feature needs richer per-project chrome (e.g. a
  channel-like sub-list), it has nowhere to go without reintroducing a
  middle column.

## Alternatives Considered

- **Keep the Projects tab, add rail icons alongside it** — rejected as
  redundant; it would leave two ways to switch projects that need to stay
  in sync for no benefit.
- **Keep a middle column reserved for future per-project navigation** —
  rejected for now (nothing to put in it yet); can be reintroduced later
  if a real need shows up, per the "Negative / Risks" note above.
