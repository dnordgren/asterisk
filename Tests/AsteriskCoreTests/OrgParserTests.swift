import AsteriskCore
import Testing

@Test
func parsesThreeLevelOutlineWithArtifacts() {
    let source = """
    #+title: Weekly Notes

    * TODO Inbox
    ** TODO Ship parser :swift:ios:
    SCHEDULED: <2026-03-22 Sun>
    :PROPERTIES:
    :Effort: 2h
    :Owner: Derek
    :END:
    Capture the initial parser and the Mail-like split view.
    - [ ] Support files from Files.app
    - [X] Keep the scope tight
    *** UI Notes
    Asterisk should feel like Mail.app, not a text editor.
    :LOGBOOK:
    - State "DONE" from "TODO" [2026-03-22 Sun 09:00]
    :END:

    * Running Notes
    ** 2026-03-22 Architecture
    CLOSED: [2026-03-22 Sun 20:30]
    We can parse only the subset we render well.
    """

    let document = OrgParser().parse(source, sourceName: "Fixture.org")

    #expect(document.sections.count == 2)
    #expect(document.artifacts.count == 2)

    let inbox = try! #require(document.sections.first)
    #expect(inbox.headline.title == "Inbox")
    #expect(inbox.entries.count == 1)

    let task = try! #require(inbox.entries.first)
    #expect(task.headline.keyword == "TODO")
    #expect(task.headline.title == "Ship parser")
    #expect(task.headline.tags == ["swift", "ios"])
    #expect(task.children.count == 1)

    #expect(task.artifacts.contains { artifact in
        if case .planning(let planning) = artifact {
            return planning.items.first?.label == "SCHEDULED"
        }
        return false
    })

    #expect(task.artifacts.contains { artifact in
        if case .propertyDrawer(let properties) = artifact {
            return properties.contains(OrgProperty(name: "Effort", value: "2h"))
        }
        return false
    })

    #expect(task.artifacts.contains { artifact in
        if case .listItem(let item) = artifact {
            return item.checkbox == .unchecked && item.text == "Support files from Files.app"
        }
        return false
    })

    let child = try! #require(task.children.first)
    #expect(child.headline.title == "UI Notes")
    #expect(child.artifacts.contains { artifact in
        if case .drawer(let name, _) = artifact {
            return name == "LOGBOOK"
        }
        return false
    })
}

@Test
func createsFallbackContainersForLooseNestedHeadings() {
    let source = """
    ** Loose task
    Body text
    """

    let document = OrgParser().parse(source, sourceName: "Loose.org")

    #expect(document.sections.count == 1)
    #expect(document.sections[0].headline.title == "Imported Items")
    #expect(document.sections[0].entries.count == 1)
    #expect(document.sections[0].entries[0].headline.title == "Loose task")
    #expect(document.sections[0].entries[0].artifacts.contains(.paragraph("Body text")))
}
