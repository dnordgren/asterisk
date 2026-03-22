# asterisk Agent Notes

## Project Shape

- The app is a hand-authored multiplatform SwiftUI Xcode project in `asterisk.xcodeproj`.
- Shared parsing/model code lives in `Sources/AsteriskCore`.
- SwiftPM is also present for fast parser-focused iteration and tests via `swift test`.

## Build Validation

- macOS app target builds successfully with `xcodebuild -project asterisk.xcodeproj -scheme asterisk -destination 'generic/platform=macOS' build`.
- iOS Simulator target builds successfully with `xcodebuild -project asterisk.xcodeproj -scheme asterisk -destination 'generic/platform=iOS Simulator' build`.
- iOS device compilation is validated with `CODE_SIGNING_ALLOWED=NO`. A real device run still requires a configured development team in Xcode.

## Known Constraints

- `Sources/AsteriskCLI` must not use a file literally named `main.swift` if it also uses an `@main` type. Keep the current `AsteriskCLI.swift` pattern.
- `URL.BookmarkCreationOptions.withSecurityScope` and the matching resolution option are macOS-only. iOS/iPadOS must use non-security-scoped bookmark options.
- The app currently exposes its Documents directory to Files.app and seeds fixture files from the bundled `LocalFixtures` folder on launch.
- Fixture seeding is additive only. Existing files in Documents are not overwritten.

## Fixture Workflow

- Put local `.org` or `.txt` files in `LocalFixtures/`.
- That folder is gitignored except for `.gitkeep`.
- Rebuild and rerun the app after adding or changing files.
- Delete the app from the simulator to force a clean reseed when needed.

## Current Org POC Scope

- Parse and render `*`, `**`, `***` headings.
- Parse and render paragraphs, blank lines, planning lines, property drawers, generic drawers, and list/checklist items.
- Preserve unsupported deeper structures conservatively rather than inventing UI for them.
