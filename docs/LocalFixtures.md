# Local Fixtures

Use `/Users/derek.nordgren/gastown/personal/asterisk/LocalFixtures` for ad hoc `.org` and `.txt` files you do not want in git.

How it works:

- The folder is bundled into the app at build time.
- On every launch, the app can copy any bundled `.org` or `.txt` files into its Documents directory for Files.app visibility.
- In the iOS Simulator, launching with `-reset-fixtures` also clears previously seeded fixture files, clears stored bookmarks, recopies the bundled fixtures, and imports them into the app automatically.
- Because the app exposes its Documents directory to Files.app, those files appear under `On My iPhone` or `On My iPad` inside the `asterisk` app container.

Recommended simulator workflow:

- Put ad hoc `.org` or `.txt` files in `LocalFixtures/`.
- Rebuild the app in Xcode after adding or changing files so they get bundled.
- Edit the scheme and add the launch argument `-reset-fixtures` for Simulator runs when you want a clean, deterministic fixture state.
- Run the app. The fixture files should appear in the app sidebar without using the file importer.

Notes:

- Existing copied files are still additive on normal launches without `-reset-fixtures`.
- `xcrun simctl addmedia booted` is not applicable here; it imports into simulator media libraries, not this app's sandboxed Documents directory.
- Drag and drop into the Simulator is also not the primary harness for this app, because the app UI restores bookmarked file URLs rather than scanning arbitrary dropped files from its sandbox.
