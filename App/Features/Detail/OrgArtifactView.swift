import SwiftUI

#if canImport(AsteriskCore)
import AsteriskCore
#endif

struct OrgArtifactView: View {
    let artifact: OrgArtifact

    var body: some View {
        switch artifact {
        case .paragraph(let text):
            Text(text)
                .font(.body)
                .textSelection(.enabled)
        case .planning(let planning):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(planning.items, id: \.label) { item in
                    Label {
                        Text("\(item.label.capitalized): \(item.value)")
                    } icon: {
                        Image(systemName: iconName(for: item.kind))
                    }
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        case .propertyDrawer(let properties):
            VStack(alignment: .leading, spacing: 8) {
                Text("Properties")
                    .font(.headline)

                ForEach(properties, id: \.name) { property in
                    HStack(alignment: .top, spacing: 12) {
                        Text(property.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 90, alignment: .leading)

                        Text(property.value)
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        case .drawer(let name, let lines):
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(.headline)

                ForEach(Array(lines.enumerated()), id: \.offset) { item in
                    Text(item.element)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        case .listItem(let item):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: checkboxSymbol(for: item.checkbox))
                    .foregroundStyle(item.checkbox == .checked ? .green : .secondary)
                    .frame(width: 20)

                Text(item.text)
                    .font(.body)
            }
            .padding(.leading, CGFloat(item.indent) * 8)
        case .blankLine:
            Color.clear
                .frame(height: 4)
        case .raw(let text):
            Text(text)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private func iconName(for kind: OrgPlanningItem.Kind) -> String {
        switch kind {
        case .scheduled:
            return "calendar"
        case .deadline:
            return "exclamationmark.circle"
        case .closed:
            return "checkmark.circle"
        case .other:
            return "clock"
        }
    }

    private func checkboxSymbol(for checkbox: OrgListItem.CheckboxState?) -> String {
        switch checkbox {
        case .unchecked:
            return "circle"
        case .checked:
            return "checkmark.circle.fill"
        case .partial:
            return "minus.circle"
        case .none:
            return "smallcircle.filled.circle"
        }
    }
}
