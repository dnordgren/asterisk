import SwiftUI

#if canImport(AsteriskCore)
import AsteriskCore
#endif

struct OrgEntryDetailView: View {
    let entry: OrgEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.headline.title)
                        .font(.largeTitle.weight(.semibold))

                    if entry.headline.keyword != nil || entry.headline.tags.isEmpty == false {
                        HStack(spacing: 12) {
                            if let keyword = entry.headline.keyword {
                                Text(keyword)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                            }

                            if entry.headline.tags.isEmpty == false {
                                Text(entry.headline.tags.map { "#\($0)" }.joined(separator: " "))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                ForEach(Array(entry.artifacts.enumerated()), id: \.offset) { item in
                    OrgArtifactView(artifact: item.element)
                }

                if entry.children.isEmpty == false {
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nested Notes")
                            .font(.title3.weight(.semibold))

                        ForEach(entry.children) { child in
                            VStack(alignment: .leading, spacing: 12) {
                                Divider()

                                Text(child.headline.title)
                                    .font(.headline)

                                ForEach(Array(child.artifacts.enumerated()), id: \.offset) { item in
                                    OrgArtifactView(artifact: item.element)
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(entry.headline.title)
    }
}
