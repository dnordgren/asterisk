# Local Fixtures

Use `/Users/derek.nordgren/gastown/personal/asterisk/LocalFixtures` for ad hoc `.org` and `.txt` files you do not want in git.

How it works:

- The folder is bundled into the app at build time.
- On launch, the app copies any `.org` or `.txt` files from that bundled folder into the app's Documents directory if they are not already present.
- Because the app exposes its Documents directory to Files.app, those files appear under `On My iPhone` or `On My iPad` inside the `asterisk` app container.

Notes:

- Rebuild and rerun the app after adding new files so they get bundled.
- Existing copied files are not overwritten on launch.
- Delete the app from the simulator if you want a clean fixture reset.
