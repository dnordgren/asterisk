import Foundation

#if canImport(AsteriskCore)
import AsteriskCore
#endif

@MainActor
final class OrgDocumentStore: ObservableObject {
    struct ImportedDocument: Identifiable {
        let id: UUID
        let displayName: String
        let bookmarkData: Data
        let resolvedURL: URL
        let document: OrgDocument
    }

    struct SectionSelection: Hashable {
        let documentID: UUID
        let sectionID: UUID
    }

    struct EntrySelection: Hashable {
        let documentID: UUID
        let sectionID: UUID
        let entryID: UUID
    }

    @Published private(set) var documents: [ImportedDocument] = []

    private let parser = OrgParser()
    private let defaultsKey = "Asterisk.StoredBookmarks"

    func documentAndSection(for selection: SectionSelection?) -> (ImportedDocument, OrgSection)? {
        guard let selection,
              let document = documents.first(where: { $0.id == selection.documentID }),
              let section = document.document.sections.first(where: { $0.id == selection.sectionID }) else {
            return nil
        }

        return (document, section)
    }

    func entry(for selection: EntrySelection?) -> OrgEntry? {
        guard let selection else { return nil }

        return documents
            .first(where: { $0.id == selection.documentID })?
            .document
            .sections.first(where: { $0.id == selection.sectionID })?
            .entries.first(where: { $0.id == selection.entryID })
    }

    func contains(sectionSelection: SectionSelection?) -> Bool {
        documentAndSection(for: sectionSelection) != nil
    }

    func contains(entrySelection: EntrySelection?) -> Bool {
        entry(for: entrySelection) != nil
    }

    func firstAvailableSectionSelection() -> SectionSelection? {
        guard let firstDocument = documents.first,
              let firstSection = firstDocument.document.sections.first else {
            return nil
        }

        return SectionSelection(documentID: firstDocument.id, sectionID: firstSection.id)
    }

    func firstEntrySelection(for selection: SectionSelection?) -> EntrySelection? {
        guard let selection,
              let entry = documentAndSection(for: selection)?.1.entries.first else {
            return nil
        }

        return EntrySelection(
            documentID: selection.documentID,
            sectionID: selection.sectionID,
            entryID: entry.id
        )
    }

    func importFiles(at urls: [URL]) async {
        let imported = importDocuments(at: urls)
        guard imported.isEmpty == false else { return }

        merge(imported)
        persistBookmarks()
    }

    func restorePersistedFiles() async {
        guard let storedBookmarks = UserDefaults.standard.array(forKey: defaultsKey) as? [Data] else {
            return
        }

        var imported: [ImportedDocument] = []

        for bookmark in storedBookmarks {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: bookmarkResolutionOptions,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if let document = try loadDocument(from: url, bookmarkData: bookmark) {
                    imported.append(document)
                }

                if isStale {
                    persistBookmarks()
                }
            } catch {
                continue
            }
        }

        merge(imported)
    }

    func resetAndImportFixtureFiles(at urls: [URL]) async {
        documents = []
        UserDefaults.standard.removeObject(forKey: defaultsKey)

        let imported = importDocuments(at: urls)
        guard imported.isEmpty == false else { return }

        merge(imported)
        persistBookmarks()
    }

    private func merge(_ imported: [ImportedDocument]) {
        var merged = documents

        for document in imported {
            if let index = merged.firstIndex(where: { $0.resolvedURL.path == document.resolvedURL.path }) {
                merged[index] = document
            } else {
                merged.append(document)
            }
        }

        documents = merged.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func importDocuments(at urls: [URL]) -> [ImportedDocument] {
        var imported: [ImportedDocument] = []

        for url in urls {
            do {
                if let document = try loadDocument(from: url) {
                    imported.append(document)
                }
            } catch {
                continue
            }
        }

        return imported
    }

    private func loadDocument(from url: URL, bookmarkData: Data? = nil) throws -> ImportedDocument? {
        let scopeStarted = url.startAccessingSecurityScopedResource()
        defer {
            if scopeStarted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let source = try String(contentsOf: url, encoding: .utf8)
        let bookmark: Data

        if let bookmarkData {
            bookmark = bookmarkData
        } else {
            bookmark = try makeBookmark(for: url)
        }

        let parsed = parser.parse(source, sourceName: url.lastPathComponent)

        return ImportedDocument(
            id: UUID(),
            displayName: url.deletingPathExtension().lastPathComponent,
            bookmarkData: bookmark,
            resolvedURL: url,
            document: parsed
        )
    }

    private func persistBookmarks() {
        let bookmarks = documents.map(\.bookmarkData)
        UserDefaults.standard.set(bookmarks, forKey: defaultsKey)
    }

    private var bookmarkResolutionOptions: URL.BookmarkResolutionOptions {
        #if os(macOS)
        return [.withSecurityScope]
        #else
        return []
        #endif
    }

    private func makeBookmark(for url: URL) throws -> Data {
        #if os(macOS)
        return try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #else
        return try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #endif
    }
}
