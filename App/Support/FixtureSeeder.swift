import Foundation

enum FixtureSeeder {
    static func seedBundledFixturesIntoDocuments() {
        guard let bundledFixturesURL = Bundle.main.url(forResource: "LocalFixtures", withExtension: nil) else {
            return
        }

        let fileManager = FileManager.default

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        guard let fixtureURLs = try? fileManager.contentsOfDirectory(
            at: bundledFixturesURL,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for fixtureURL in fixtureURLs {
            let filename = fixtureURL.lastPathComponent.lowercased()
            guard filename.hasSuffix(".org") || filename.hasSuffix(".txt") else {
                continue
            }

            let destinationURL = documentsURL.appendingPathComponent(fixtureURL.lastPathComponent)

            if fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }

            try? fileManager.copyItem(at: fixtureURL, to: destinationURL)
        }
    }
}
