# asterisk Scaffold Plan

## Phase 1: Shared Core

- Model the strict subset of org-mode that asterisk is willing to render.
- Parse `*`, `**`, and `***` headings into a Mail-like hierarchy.
- Preserve nearby org artifacts as typed nodes:
  - planning lines (`SCHEDULED`, `DEADLINE`, `CLOSED`)
  - property drawers
  - generic drawers like `LOGBOOK`
  - list and checklist items
  - paragraphs and blank lines
  - unsupported deeper headings as raw artifacts
- Keep the parser deterministic and line-oriented so it is easier to debug and safer to round-trip later.

## Phase 2: Multiplatform App Shell

- Use one multiplatform SwiftUI app target for iOS, iPadOS, and macOS.
- Base navigation on `NavigationSplitView`:
  - sidebar: imported files grouped into top-level `*` sections
  - content: `**` entries for the selected section
  - detail: rendered entry view showing body artifacts and `***` subentries
- Import files through `fileImporter` so the iOS and iPadOS experience lines up with Files.app.
- Persist security-scoped bookmarks for imported files so the sidebar can restore previous sources across launches.

## Phase 3: POC UX

- Prioritize read-only rendering first.
- Render TODO keywords, tags, planning metadata, property drawers, and checklist items with native SwiftUI components.
- Keep editing out of scope for the first pass except for future model seams:
  - artifacts remain typed
  - file access is isolated in a store
  - parser output is deterministic enough to support later serialization

## Phase 4: Near-Term Follow-Ups

- Add write-back support for toggling TODO state and checklist items.
- Add richer org handling only when it has a clear UI representation.
- Introduce snapshot tests for parser output and UI previews for known fixture files.
