import Foundation

#if canImport(AsteriskCore)
import AsteriskCore
#endif

enum FixtureSeeder {
    static func shouldResetFixturesOnLaunch(processInfo: ProcessInfo = .processInfo) -> Bool {
        #if DEBUG && targetEnvironment(simulator)
        return processInfo.arguments.contains("-reset-fixtures")
            || processInfo.environment["ASTERISK_RESET_FIXTURES"] == "1"
        #else
        return false
        #endif
    }

    static func bundledFixtureURLs(
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) -> [URL] {
        guard let bundledFixturesURL = bundle.url(forResource: "LocalFixtures", withExtension: nil),
              let fixtureURLs = try? fileManager.contentsOfDirectory(
                at: bundledFixturesURL,
                includingPropertiesForKeys: nil
              ) else {
            return []
        }

        return FixtureFileSupport.supportedFixtureURLs(in: fixtureURLs)
    }

    static func seedBundledFixturesIntoDocuments(
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) -> [URL] {
        guard let documentsURL = documentsDirectoryURL(fileManager: fileManager) else {
            return []
        }

        let bundledFixtures = bundledFixtureURLs(bundle: bundle, fileManager: fileManager)

        for fixtureURL in bundledFixtures {
            let destinationURL = documentsURL.appendingPathComponent(fixtureURL.lastPathComponent)

            if fileManager.fileExists(atPath: destinationURL.path) == false {
                try? fileManager.copyItem(at: fixtureURL, to: destinationURL)
            }
        }

        return bundledFixtures.map { documentsURL.appendingPathComponent($0.lastPathComponent) }
    }

    static func resetSeededFixturesInDocuments(fileManager: FileManager = .default) {
        guard let documentsURL = documentsDirectoryURL(fileManager: fileManager),
              let existingURLs = try? fileManager.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: nil
              ) else {
            return
        }

        for fixtureURL in FixtureFileSupport.supportedFixtureURLs(in: existingURLs) {
            try? fileManager.removeItem(at: fixtureURL)
        }
    }

    private static func documentsDirectoryURL(fileManager: FileManager) -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
