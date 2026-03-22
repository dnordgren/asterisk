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
    @Published var selectedSection: SectionSelection?
    @Published var selectedEntry: EntrySelection?

    private let parser = OrgParser()
    private let defaultsKey = "Asterisk.StoredBookmarks"

    var currentSection: OrgSection? {
        guard let selectedSection else { return nil }
        return documents
            .first(where: { $0.id == selectedSection.documentID })?
            .document
            .sections
            .first(where: { $0.id == selectedSection.sectionID })
    }

    var currentEntry: OrgEntry? {
        guard let selectedEntry else { return nil }
        return documents
            .first(where: { $0.id == selectedEntry.documentID })?
            .document
            .sections
            .first(where: { $0.id == selectedEntry.sectionID })?
            .entries
            .first(where: { $0.id == selectedEntry.entryID })
    }

    func importFiles(at urls: [URL]) async {
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

        guard imported.isEmpty == false else { return }

        merge(imported)
        persistBookmarks()

        if selectedSection == nil,
           let firstDocument = documents.first,
           let firstSection = firstDocument.document.sections.first {
            select(sectionID: firstSection.id, in: firstDocument.id)
        }
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

        if selectedSection == nil,
           let firstDocument = documents.first,
           let firstSection = firstDocument.document.sections.first {
            select(sectionID: firstSection.id, in: firstDocument.id)
        }
    }

    func select(sectionID: UUID, in documentID: UUID) {
        selectedSection = SectionSelection(documentID: documentID, sectionID: sectionID)
        selectedEntry = nil

        if let section = documents.first(where: { $0.id == documentID })?
            .document.sections.first(where: { $0.id == sectionID }),
           let entry = section.entries.first {
            selectedEntry = EntrySelection(
                documentID: documentID,
                sectionID: sectionID,
                entryID: entry.id
            )
        }
    }

    func select(entryID: UUID, in sectionID: UUID, documentID: UUID) {
        selectedEntry = EntrySelection(
            documentID: documentID,
            sectionID: sectionID,
            entryID: entryID
        )
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
