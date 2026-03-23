import SwiftUI

@main
struct AsteriskApp: App {
    @StateObject private var library = OrgDocumentStore()

    var body: some Scene {
        WindowGroup {
            LibraryRootView()
                .environmentObject(library)
                .task {
                    if FixtureSeeder.shouldResetFixturesOnLaunch() {
                        FixtureSeeder.resetSeededFixturesInDocuments()
                        let fixtureURLs = FixtureSeeder.seedBundledFixturesIntoDocuments()
                        await library.resetAndImportFixtureFiles(at: fixtureURLs)
                    } else {
                        FixtureSeeder.seedBundledFixturesIntoDocuments()
                        await library.restorePersistedFiles()
                    }
                }
        }
    }
}
