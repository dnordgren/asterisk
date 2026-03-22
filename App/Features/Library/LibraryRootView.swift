import SwiftUI

#if canImport(AsteriskCore)
import AsteriskCore
#endif

struct LibraryRootView: View {
    @EnvironmentObject private var store: OrgDocumentStore
    @State private var isImporting = false

    var body: some View {
        NavigationSplitView {
            List(selection: $store.selectedSection) {
                ForEach(store.documents) { document in
                    Section(document.displayName) {
                        ForEach(document.document.sections) { section in
                            Button {
                                store.select(sectionID: section.id, in: document.id)
                            } label: {
                                Label(section.headline.title, systemImage: "folder")
                            }
                            .tag(OrgDocumentStore.SectionSelection(documentID: document.id, sectionID: section.id))
                        }
                    }
                }
            }
            .navigationTitle("asterisk")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Org File", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.orgFile, .plainText],
                allowsMultipleSelection: true
            ) { result in
                guard case .success(let urls) = result else { return }
                Task {
                    await store.importFiles(at: urls)
                }
            }
        } content: {
            if let selection = store.selectedSection,
               let document = store.documents.first(where: { $0.id == selection.documentID }),
               let section = document.document.sections.first(where: { $0.id == selection.sectionID }) {
                List(selection: $store.selectedEntry) {
                    ForEach(section.entries) { entry in
                        Button {
                            store.select(entryID: entry.id, in: section.id, documentID: document.id)
                        } label: {
                            EntryRowView(entry: entry)
                        }
                        .tag(
                            OrgDocumentStore.EntrySelection(
                                documentID: document.id,
                                sectionID: section.id,
                                entryID: entry.id
                            )
                        )
                    }
                }
                .navigationTitle(section.headline.title)
            } else {
                ContentUnavailableView(
                    "Choose a Section",
                    systemImage: "sidebar.left",
                    description: Text("Import an org file from Files to populate the sidebar.")
                )
            }
        } detail: {
            if let entry = store.currentEntry {
                OrgEntryDetailView(entry: entry)
            } else {
                ContentUnavailableView(
                    "Select an Entry",
                    systemImage: "doc.text",
                    description: Text("Second-level org headings render here with parsed artifacts and third-level children.")
                )
            }
        }
    }
}

private struct EntryRowView: View {
    let entry: OrgEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let keyword = entry.headline.keyword {
                    Text(keyword)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(keyword == "DONE" ? .green : .blue)
                }

                Text(entry.headline.title)
                    .font(.headline)
                    .lineLimit(1)
            }

            if entry.headline.tags.isEmpty == false {
                Text(entry.headline.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let preview = previewText {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var previewText: String? {
        for artifact in entry.artifacts {
            if case .paragraph(let text) = artifact {
                return text
            }
        }
        return nil
    }
}
