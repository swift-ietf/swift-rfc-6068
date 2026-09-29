import RFC_3986
import RFC_5322
import RFC_6068
import Testing

@Suite
struct `RFC_6068.Mailto Tests` {

    @Test
    func `a mailto addresses a single mailbox`() throws {
        let mailto = RFC_6068.Mailto(to: [try RFC_5322.Mailbox("chris@example.com")])

        #expect(mailto.to.count == 1)
        #expect(mailto.to.first?.address == "chris@example.com")
        #expect(mailto.headers.isEmpty)
    }

    @Test
    func `a mailto keeps the display name of a recipient`() throws {
        let mailto = RFC_6068.Mailto(to: [try RFC_5322.Mailbox("Jane Doe <jane@example.com>")])

        #expect(mailto.to.first?.displayName == "Jane Doe")
        #expect(mailto.to.first?.address == "jane@example.com")
    }

    @Test
    func `a mailto exposes its subject and body`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("infobot@example.com")],
            headers: [try .subject("current-issue"), try .body("send current-issue")]
        )

        #expect(mailto.subject == "current-issue")
        #expect(mailto.body == "send current-issue")
    }

    @Test
    func `a mailto without recipients carries only headers`() throws {
        let mailto = RFC_6068.Mailto(headers: [try .subject("Test")])

        #expect(mailto.to.isEmpty)
        #expect(mailto.subject == "Test")
        #expect(mailto.body == nil)
    }

    @Test
    func `header names read case-insensitively`() throws {
        let mailto = RFC_6068.Mailto(headers: [try RFC_6068.Mailto.Header(name: "Subject", value: "Hello")])

        #expect(mailto.subject == "Hello")
    }

    @Test
    func `recipients in a to header join the path recipients`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("list@example.com")],
            headers: [try .to("admin@example.com")]
        )

        #expect(mailto.allTo.map(\.address) == ["list@example.com", "admin@example.com"])
    }

    @Test
    func `cc and bcc headers read as mailboxes`() throws {
        let mailto = RFC_6068.Mailto(
            headers: [try .cc("manager@example.com"), try .bcc("archive@example.com")]
        )

        #expect(mailto.cc.map(\.address) == ["manager@example.com"])
        #expect(mailto.bcc.map(\.address) == ["archive@example.com"])
    }

    @Test
    func `a cc header that is not a mailbox is left out`() throws {
        let mailto = RFC_6068.Mailto(headers: [try .cc("not a mailbox")])

        #expect(mailto.cc.isEmpty)
    }

    @Test
    func `the qchar set allows the some-delims and forbids the header separators`() {
        let qchar = RFC_3986.ByteSet.mailto.qchar

        #expect(qchar.contains(UInt8(ascii: "!")))
        #expect(qchar.contains(UInt8(ascii: "@")))
        #expect(qchar.contains(UInt8(ascii: "~")))
        #expect(!qchar.contains(UInt8(ascii: "&")))
        #expect(!qchar.contains(UInt8(ascii: "=")))
        #expect(!qchar.contains(UInt8(ascii: "?")))
    }

    @Test
    func `the addr-spec set keeps the at sign and the dot unencoded`() {
        let addrSpec = RFC_3986.ByteSet.mailto.addrSpec

        #expect(addrSpec.contains(UInt8(ascii: "@")))
        #expect(addrSpec.contains(UInt8(ascii: ".")))
        #expect(!addrSpec.contains(UInt8(ascii: ",")))
        #expect(!addrSpec.contains(UInt8(ascii: "?")))
    }
}
