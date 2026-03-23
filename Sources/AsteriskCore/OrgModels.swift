import Foundation

public struct OrgDocument: Equatable, Sendable {
    public var sourceName: String
    public var artifacts: [OrgArtifact]
    public var sections: [OrgSection]

    public init(
        sourceName: String,
        artifacts: [OrgArtifact] = [],
        sections: [OrgSection] = []
    ) {
        self.sourceName = sourceName
        self.artifacts = artifacts
        self.sections = sections
    }
}

public struct OrgSection: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var headline: OrgHeadline
    public var artifacts: [OrgArtifact]
    public var entries: [OrgEntry]

    public init(
        id: UUID = UUID(),
        headline: OrgHeadline,
        artifacts: [OrgArtifact] = [],
        entries: [OrgEntry] = []
    ) {
        self.id = id
        self.headline = headline
        self.artifacts = artifacts
        self.entries = entries
    }
}

public struct OrgEntry: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var headline: OrgHeadline
    public var artifacts: [OrgArtifact]
    public var children: [OrgSubentry]

    public init(
        id: UUID = UUID(),
        headline: OrgHeadline,
        artifacts: [OrgArtifact] = [],
        children: [OrgSubentry] = []
    ) {
        self.id = id
        self.headline = headline
        self.artifacts = artifacts
        self.children = children
    }
}

public struct OrgSubentry: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var headline: OrgHeadline
    public var artifacts: [OrgArtifact]

    public init(
        id: UUID = UUID(),
        headline: OrgHeadline,
        artifacts: [OrgArtifact] = []
    ) {
        self.id = id
        self.headline = headline
        self.artifacts = artifacts
    }
}

public struct OrgHeadline: Equatable, Sendable {
    public var level: Int
    public var keyword: String?
    public var title: String
    public var tags: [String]
    public var rawValue: String

    public init(
        level: Int,
        keyword: String? = nil,
        title: String,
        tags: [String] = [],
        rawValue: String
    ) {
        self.level = level
        self.keyword = keyword
        self.title = title
        self.tags = tags
        self.rawValue = rawValue
    }
}

public enum OrgArtifact: Equatable, Sendable {
    case paragraph(String)
    case planning(OrgPlanning)
    case propertyDrawer([OrgProperty])
    case drawer(name: String, lines: [String])
    case listItem(OrgListItem)
    case blankLine
    case raw(String)
}

public struct OrgPlanning: Equatable, Sendable {
    public var items: [OrgPlanningItem]

    public init(items: [OrgPlanningItem]) {
        self.items = items
    }
}

public struct OrgPlanningItem: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case scheduled = "SCHEDULED"
        case deadline = "DEADLINE"
        case closed = "CLOSED"
        case other
    }

    public var kind: Kind
    public var label: String
    public var value: String

    public init(kind: Kind, label: String, value: String) {
        self.kind = kind
        self.label = label
        self.value = value
    }
}

public struct OrgProperty: Equatable, Sendable {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

public struct OrgListItem: Equatable, Sendable {
    public enum CheckboxState: Equatable, Sendable {
        case unchecked
        case checked
        case partial
    }

    public var indent: Int
    public var marker: String
    public var checkbox: CheckboxState?
    public var text: String

    public init(
        indent: Int,
        marker: String,
        checkbox: CheckboxState? = nil,
        text: String
    ) {
        self.indent = indent
        self.marker = marker
        self.checkbox = checkbox
        self.text = text
    }
}

public enum FixtureFileSupport {
    public static let supportedExtensions: Set<String> = ["org", "txt"]

    public static func isSupportedFixtureURL(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    public static func supportedFixtureURLs(in urls: [URL]) -> [URL] {
        urls
            .filter(isSupportedFixtureURL)
            .sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
    }
}
