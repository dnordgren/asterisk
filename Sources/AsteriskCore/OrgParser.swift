import Foundation

public struct OrgParser: Sendable {
    fileprivate static let todoKeywords: Set<String> = [
        "TODO",
        "DONE",
        "NEXT",
        "WAITING",
        "CANCELLED",
    ]

    public init() {}

    public func parse(_ source: String, sourceName: String) -> OrgDocument {
        var parser = ParserState(sourceName: sourceName)
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")

        for line in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            parser.consume(String(line))
        }

        parser.finish()
        return parser.document
    }
}

private struct ParserState {
    private enum DrawerState {
        case properties([OrgProperty])
        case generic(name: String, lines: [String])
    }

    private(set) var document: OrgDocument
    private var sectionIndex: Int?
    private var entryIndex: Int?
    private var subentryIndex: Int?
    private var paragraphBuffer: [String] = []
    private var drawerState: DrawerState?

    init(sourceName: String) {
        self.document = OrgDocument(sourceName: sourceName)
    }

    mutating func consume(_ line: String) {
        if let headline = parseHeadline(line) {
            flushPendingArtifacts()
            appendHeadline(headline)
            return
        }

        if drawerState != nil {
            consumeDrawerLine(line)
            return
        }

        if line == ":PROPERTIES:" {
            flushParagraph()
            drawerState = .properties([])
            return
        }

        if line.hasPrefix(":"),
           line.hasSuffix(":"),
           line.count > 2,
           line != ":END:" {
            flushParagraph()
            let name = String(line.dropFirst().dropLast())
            drawerState = .generic(name: name, lines: [])
            return
        }

        if let planning = parsePlanning(line) {
            flushParagraph()
            appendArtifact(.planning(planning))
            return
        }

        if let listItem = parseListItem(line) {
            flushParagraph()
            appendArtifact(.listItem(listItem))
            return
        }

        if line.trimmingCharacters(in: .whitespaces).isEmpty {
            flushParagraph()
            appendArtifact(.blankLine)
            return
        }

        paragraphBuffer.append(line)
    }

    mutating func finish() {
        flushPendingArtifacts()
    }

    private mutating func flushPendingArtifacts() {
        flushParagraph()

        if let drawerState {
            switch drawerState {
            case .properties(let properties):
                appendArtifact(.propertyDrawer(properties))
            case .generic(let name, let lines):
                appendArtifact(.drawer(name: name, lines: lines))
            }
            self.drawerState = nil
        }
    }

    private mutating func flushParagraph() {
        guard paragraphBuffer.isEmpty == false else { return }
        let text = paragraphBuffer.joined(separator: "\n")
        appendArtifact(.paragraph(text))
        paragraphBuffer.removeAll(keepingCapacity: true)
    }

    private mutating func consumeDrawerLine(_ line: String) {
        guard let drawerState else { return }

        if line == ":END:" {
            switch drawerState {
            case .properties(let properties):
                appendArtifact(.propertyDrawer(properties))
            case .generic(let name, let lines):
                appendArtifact(.drawer(name: name, lines: lines))
            }
            self.drawerState = nil
            return
        }

        switch drawerState {
        case .properties(var properties):
            if let property = parseProperty(line) {
                properties.append(property)
            } else {
                properties.append(OrgProperty(name: "RAW", value: line))
            }
            self.drawerState = .properties(properties)
        case .generic(let name, var lines):
            lines.append(line)
            self.drawerState = .generic(name: name, lines: lines)
        }
    }

    private mutating func appendHeadline(_ headline: OrgHeadline) {
        switch headline.level {
        case 1:
            document.sections.append(OrgSection(headline: headline))
            sectionIndex = document.sections.indices.last
            entryIndex = nil
            subentryIndex = nil
        case 2:
            ensureFallbackSectionIfNeeded()
            guard let sectionIndex else { return }
            document.sections[sectionIndex].entries.append(OrgEntry(headline: headline))
            entryIndex = document.sections[sectionIndex].entries.indices.last
            subentryIndex = nil
        case 3:
            ensureFallbackSectionIfNeeded()
            ensureFallbackEntryIfNeeded()
            guard let sectionIndex, let entryIndex else { return }
            document.sections[sectionIndex].entries[entryIndex].children.append(OrgSubentry(headline: headline))
            subentryIndex = document.sections[sectionIndex].entries[entryIndex].children.indices.last
        default:
            appendArtifact(.raw(lineForUnsupportedHeadline(headline)))
        }
    }

    private func lineForUnsupportedHeadline(_ headline: OrgHeadline) -> String {
        String(repeating: "*", count: headline.level) + " " + headline.rawValue
    }

    private mutating func appendArtifact(_ artifact: OrgArtifact) {
        if let sectionIndex, let entryIndex, let subentryIndex {
            document.sections[sectionIndex].entries[entryIndex].children[subentryIndex].artifacts.append(artifact)
            return
        }

        if let sectionIndex, let entryIndex {
            document.sections[sectionIndex].entries[entryIndex].artifacts.append(artifact)
            return
        }

        if let sectionIndex {
            document.sections[sectionIndex].artifacts.append(artifact)
            return
        }

        document.artifacts.append(artifact)
    }

    private mutating func ensureFallbackSectionIfNeeded() {
        guard sectionIndex == nil else { return }
        let headline = OrgHeadline(
            level: 1,
            title: "Imported Items",
            rawValue: "Imported Items"
        )
        document.sections.append(OrgSection(headline: headline))
        sectionIndex = document.sections.indices.last
    }

    private mutating func ensureFallbackEntryIfNeeded() {
        guard entryIndex == nil else { return }
        guard let sectionIndex else { return }
        let headline = OrgHeadline(
            level: 2,
            title: "Loose Notes",
            rawValue: "Loose Notes"
        )
        document.sections[sectionIndex].entries.append(OrgEntry(headline: headline))
        entryIndex = document.sections[sectionIndex].entries.indices.last
    }

    private func parseHeadline(_ line: String) -> OrgHeadline? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("*") else { return nil }

        let stars = trimmed.prefix { $0 == "*" }
        let level = stars.count
        guard level > 0 else { return nil }

        let remainder = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
        guard remainder.isEmpty == false else {
            return OrgHeadline(level: level, title: "", rawValue: "")
        }

        let tagPattern = /^(.*?)(?:\s+(:[A-Za-z0-9_@#%:.-]+:))?$/
        let match = remainder.wholeMatch(of: tagPattern)
        let content = match?.1.trimmingCharacters(in: .whitespaces) ?? String(remainder)
        let tagString = match?.2.map(String.init)

        var keyword: String?
        var title = content

        let pieces = content.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if let candidate = pieces.first.map(String.init),
           OrgParser.todoKeywords.contains(candidate) {
            keyword = candidate
            title = pieces.count > 1 ? String(pieces[1]) : ""
        }

        let tags = tagString?
            .split(separator: ":")
            .map(String.init)
            .filter { $0.isEmpty == false } ?? []

        return OrgHeadline(
            level: level,
            keyword: keyword,
            title: title,
            tags: tags,
            rawValue: String(remainder)
        )
    }

    private func parsePlanning(_ line: String) -> OrgPlanning? {
        let tokenPattern = /(SCHEDULED|DEADLINE|CLOSED):\s+([<\[].*?[>\]])/
        let matches = line.matches(of: tokenPattern)
        guard matches.isEmpty == false else { return nil }

        let items = matches.map { match in
            let label = String(match.1)
            let value = String(match.2)
            let kind = OrgPlanningItem.Kind(rawValue: label) ?? .other
            return OrgPlanningItem(kind: kind, label: label, value: value)
        }

        return OrgPlanning(items: items)
    }

    private func parseProperty(_ line: String) -> OrgProperty? {
        let pattern = /^:([A-Za-z0-9_@#%.-]+):\s*(.*)$/
        guard let match = line.wholeMatch(of: pattern) else { return nil }
        return OrgProperty(name: String(match.1), value: String(match.2))
    }

    private func parseListItem(_ line: String) -> OrgListItem? {
        let pattern = /^(\s*)([-+*]|\d+[.)])\s+(?:\[([ Xx-])\]\s+)?(.*)$/
        guard let match = line.wholeMatch(of: pattern) else { return nil }

        let indent = String(match.1).count
        let marker = String(match.2)
        let checkbox = match.3.flatMap { raw -> OrgListItem.CheckboxState? in
            switch raw {
            case " ":
                return .unchecked
            case "X", "x":
                return .checked
            case "-":
                return .partial
            default:
                return nil
            }
        }

        return OrgListItem(
            indent: indent,
            marker: marker,
            checkbox: checkbox,
            text: String(match.4)
        )
    }
}
