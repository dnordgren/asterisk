import AsteriskCore
import Darwin
import Foundation

@main
struct AsteriskCLI {
    static func main() throws {
        let arguments = CommandLine.arguments.dropFirst()

        guard let first = arguments.first else {
            fputs("usage: asterisk-cli <path-to-org-file>\n", stderr)
            Darwin.exit(64)
        }

        let url = URL(fileURLWithPath: first)
        let source = try String(contentsOf: url, encoding: .utf8)
        let document = OrgParser().parse(source, sourceName: url.lastPathComponent)
        print(render(document))
    }

    private static func render(_ document: OrgDocument) -> String {
        var lines: [String] = ["FILE \(document.sourceName)"]

        for artifact in document.artifacts {
            lines.append("  \(describe(artifact))")
        }

        for section in document.sections {
            lines.append("* \(section.headline.title)")

            for artifact in section.artifacts {
                lines.append("  \(describe(artifact))")
            }

            for entry in section.entries {
                let keyword = entry.headline.keyword.map { "\($0) " } ?? ""
                lines.append("  ** \(keyword)\(entry.headline.title)")

                for artifact in entry.artifacts {
                    lines.append("    \(describe(artifact))")
                }

                for child in entry.children {
                    let childKeyword = child.headline.keyword.map { "\($0) " } ?? ""
                    lines.append("    *** \(childKeyword)\(child.headline.title)")

                    for artifact in child.artifacts {
                        lines.append("      \(describe(artifact))")
                    }
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func describe(_ artifact: OrgArtifact) -> String {
        switch artifact {
        case .paragraph(let text):
            return "paragraph[\(text.replacingOccurrences(of: "\n", with: " | "))]"
        case .planning(let planning):
            let details = planning.items
                .map { "\($0.label)=\($0.value)" }
                .joined(separator: ", ")
            return "planning[\(details)]"
        case .propertyDrawer(let properties):
            let details = properties
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: ", ")
            return "properties[\(details)]"
        case .drawer(let name, let lines):
            return "drawer[\(name): \(lines.joined(separator: " | "))]"
        case .listItem(let item):
            let checkbox: String
            switch item.checkbox {
            case .unchecked:
                checkbox = "[ ] "
            case .checked:
                checkbox = "[x] "
            case .partial:
                checkbox = "[-] "
            case .none:
                checkbox = ""
            }
            return "list[\(String(repeating: "·", count: max(item.indent / 2, 0))) \(item.marker) \(checkbox)\(item.text)]"
        case .blankLine:
            return "blank"
        case .raw(let text):
            return "raw[\(text)]"
        }
    }
}
