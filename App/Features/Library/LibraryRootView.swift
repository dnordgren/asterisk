import SwiftUI

#if canImport(AsteriskCore)
import AsteriskCore
#endif

private enum MailListMetrics {
    static let leftGutter: CGFloat = 28
    static let rightGutter: CGFloat = 20
    static let rowVerticalPadding: CGFloat = 8
    static let rowSpacing: CGFloat = 2
    static let headerTopPadding: CGFloat = 10
    static let headerBottomPadding: CGFloat = 12
    static let previewMinHeight: CGFloat = 30
}

struct LibraryRootView: View {
    @EnvironmentObject private var store: OrgDocumentStore
    @State private var isImporting = false
    @State private var selectedSection: OrgDocumentStore.SectionSelection?
    @State private var selectedEntry: OrgDocumentStore.EntrySelection?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                ForEach(store.documents) { document in
                    Section(document.displayName) {
                        ForEach(document.document.sections) { section in
                            SidebarSectionRowView(title: section.headline.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            .tag(OrgDocumentStore.SectionSelection(documentID: document.id, sectionID: section.id))
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedSection) { _, newSelection in
                syncEntrySelection(for: newSelection)
            }
            .onReceive(store.$documents) { _ in
                syncSelectionWithDocuments()
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
            if let (document, section) = store.documentAndSection(for: selectedSection) {
                VStack(spacing: 0) {
                    ContentColumnHeaderView(
                        sectionTitle: section.headline.title,
                        documentTitle: document.displayName
                    )

                    List(selection: $selectedEntry) {
                        ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                            EntryRowView(
                                entry: entry,
                                showsDivider: index < section.entries.count - 1
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .tag(
                                OrgDocumentStore.EntrySelection(
                                    documentID: document.id,
                                    sectionID: section.id,
                                    entryID: entry.id
                                )
                            )
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            } else {
                ContentUnavailableView(
                    "Choose a Section",
                    systemImage: "sidebar.left",
                    description: Text("Import an org file from Files to populate the sidebar.")
                )
            }
        } detail: {
            if let entry = store.entry(for: selectedEntry) {
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

    private func syncSelectionWithDocuments() {
        if store.contains(sectionSelection: selectedSection) == false {
            selectedSection = store.firstAvailableSectionSelection()
        }

        syncEntrySelection(for: selectedSection)
    }

    private func syncEntrySelection(for sectionSelection: OrgDocumentStore.SectionSelection?) {
        guard let sectionSelection else {
            selectedEntry = nil
            return
        }

        let selectedEntryMatchesSection = selectedEntry?.documentID == sectionSelection.documentID &&
            selectedEntry?.sectionID == sectionSelection.sectionID

        if selectedEntryMatchesSection, store.contains(entrySelection: selectedEntry) {
            return
        }

        selectedEntry = store.firstEntrySelection(for: sectionSelection)
    }
}

private struct ContentColumnHeaderView: View {
    let sectionTitle: String
    let documentTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(sectionTitle) - \(documentTitle)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.top, MailListMetrics.headerTopPadding)
                .padding(.bottom, MailListMetrics.headerBottomPadding)
                .padding(.leading, MailListMetrics.leftGutter)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.background)
    }
}

private struct SidebarSectionRowView: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.body.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 2)
    }
}

private struct EntryRowView: View {
    let entry: OrgEntry
    let showsDivider: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Color.clear
                    .frame(width: MailListMetrics.leftGutter)

                VStack(alignment: .leading, spacing: MailListMetrics.rowSpacing) {
                    Text(subjectText)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    if let metadataText {
                        Text(metadataText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    if let preview = previewText {
                        Text(preview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, minHeight: MailListMetrics.previewMinHeight, alignment: .topLeading)
                    }
                }
                .padding(.vertical, MailListMetrics.rowVerticalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)

                Color.clear
                    .frame(width: MailListMetrics.rightGutter)
            }

            if showsDivider {
                Divider()
                    .padding(.leading, MailListMetrics.leftGutter)
                    .padding(.trailing, MailListMetrics.rightGutter)
            }
        }
    }

    private var subjectText: String {
        [entry.headline.keyword, entry.headline.title]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private var metadataText: String? {
        guard entry.headline.tags.isEmpty == false else { return nil }
        return entry.headline.tags.map { "#\($0)" }.joined(separator: " ")
    }

    private var previewText: String? {
        let segments = entry.artifacts.compactMap(previewText(for:))
        guard segments.isEmpty == false else { return nil }
        return segments.joined(separator: " ")
    }

    private func previewText(for artifact: OrgArtifact) -> String? {
        switch artifact {
        case .paragraph(let text):
            return normalizedPreviewText(text)
        case .listItem(let item):
            return normalizedPreviewText("- \(item.text)")
        case .raw(let text):
            return normalizedPreviewText(text)
        case .planning(let planning):
            let text = planning.items
                .map { "\($0.label.capitalized): \($0.value)" }
                .joined(separator: " ")
            return normalizedPreviewText(text)
        case .propertyDrawer(let properties):
            let text = properties
                .map { "\($0.name): \($0.value)" }
                .joined(separator: " ")
            return normalizedPreviewText(text)
        case .drawer(let name, let lines):
            let text = ([name] + lines).joined(separator: " ")
            return normalizedPreviewText(text)
        case .blankLine:
            return nil
        }
    }

    private func normalizedPreviewText(_ text: String) -> String? {
        let collapsed = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return collapsed.isEmpty ? nil : collapsed
    }
}
