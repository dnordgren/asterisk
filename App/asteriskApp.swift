import SwiftUI

@main
struct AsteriskApp: App {
    @StateObject private var library = OrgDocumentStore()

    var body: some Scene {
        WindowGroup {
            LibraryRootView()
                .environmentObject(library)
                .task {
                    FixtureSeeder.seedBundledFixturesIntoDocuments()
                    await library.restorePersistedFiles()
                }
        }
    }
}
