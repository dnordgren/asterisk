# asterisk

asterisk is an opinionated client for Emacs' inimitable org-mode with Swift UI. It runs on iOS, iPadOS and macOS. It has an opinionated view of org-mode files to provide a native UX for interacting with org-mode outlines.

It works best for helping you manage a set of ["one big text file"](https://jeffhuang.com/productivity_text_file/). It adheres tightly to a Mail.app analogy to leverage native UX components rather than a more traditional text or outline view:

## It's kinda like Mail.app

* **Separate org files are like separate Accounts in Mail.** It in theory supports many, but in practice is used with a relatively small number of active files.
* **Top level `*` bullets are like Folders in a Mail Account.** Perhap dozens per file, but not hundreds.
    * It assumes that top-level bullets are used primarily as "buckets" for second-level bullets, rather than containing text or rich org markup themselves
* **Second-level `**` bullets are like emails in a Mail Folder.** Second-level bullets do most of the work in asterisk. They each get a row in content views.
* Any more deeply-nested bullets are like interacting with content within a specific email.

## Design Principles

asterisk is meant to look and feel like a robust native app rather than a rickety outliner/text editor. In order to achieve this, we often need to strip down the functionality offered by full org-mode in order to something we can parse robustly, edit *relatively* atomically, and render reliably.

## Development Notes

### Build / Run / Test

#### Xcode

Open [`asterisk.xcodeproj`](./asterisk.xcodeproj) in Xcode.

Validated targets:

* macOS
* iOS Simulator
* iOS device compilation

To run in Xcode:

* Choose the `asterisk` scheme
* Pick either `My Mac` or an iPhone simulator
* Press Run

For a real iPhone run, select a development team in Signing & Capabilities first.

#### Command Line

Build the macOS app target:

```bash
xcodebuild -project asterisk.xcodeproj -scheme asterisk -destination 'generic/platform=macOS' build
```

Build the iOS Simulator target:

```bash
xcodebuild -project asterisk.xcodeproj -scheme asterisk -destination 'generic/platform=iOS Simulator' build
```

Validate iOS device compilation without signing:

```bash
xcodebuild -project asterisk.xcodeproj -scheme asterisk -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

Run parser tests:

```bash
swift test
```

Run the CLI parser against a sample org file:

```bash
swift run asterisk-cli Examples/Sample.org
```

### Local Fixtures

For Simulator testing, use the gitignored [`LocalFixtures`](./LocalFixtures) folder in the repo. Any `.org` or `.txt` files placed there are bundled into the app at build time and copied into the app's Documents directory on launch, which makes them show up in Files.app under the `asterisk` container.

See [docs/LocalFixtures.md](./docs/LocalFixtures.md) for the exact workflow and reset behavior.

### Current Parser Scope

The current POC intentionally parses a narrow org-mode subset:

* `*`, `**`, and `***` headings
* paragraphs and blank lines
* planning lines like `SCHEDULED`, `DEADLINE`, and `CLOSED`
* property drawers
* generic drawers such as `LOGBOOK`
* plain list items and checklist items

Deeper headings and unsupported constructs should be preserved conservatively rather than rendered optimistically.
