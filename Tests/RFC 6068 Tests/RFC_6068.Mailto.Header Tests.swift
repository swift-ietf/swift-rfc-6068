import RFC_6068
import Testing

@Suite
struct `RFC_6068.Mailto.Header Tests` {

    @Test
    func `the factories name the common headers`() throws {
        #expect(try RFC_6068.Mailto.Header.subject("Test").name == "subject")
        #expect(try RFC_6068.Mailto.Header.body("Content").name == "body")
        #expect(try RFC_6068.Mailto.Header.cc("a@example.com").name == "cc")
        #expect(try RFC_6068.Mailto.Header.bcc("b@example.com").name == "bcc")
        #expect(try RFC_6068.Mailto.Header.to("c@example.com").name == "to")
        #expect(try RFC_6068.Mailto.Header.inReplyTo("<id@example.com>").name == "in-reply-to")
    }

    @Test
    func `a header may carry an empty value`() throws {
        let header = try RFC_6068.Mailto.Header.body("")

        #expect(header.value.isEmpty)
    }

    @Test
    func `an empty header name is rejected`() {
        #expect(throws: RFC_6068.Mailto.Header.Error.emptyName("Hello")) {
            try RFC_6068.Mailto.Header(name: "", value: "Hello")
        }
    }

    @Test
    func `headers compare their names case-insensitively`() throws {
        let lower = try RFC_6068.Mailto.Header(name: "subject", value: "Hello")
        let upper = try RFC_6068.Mailto.Header(name: "Subject", value: "Hello")

        #expect(lower == upper)
    }

    @Test
    func `headers compare their values exactly`() throws {
        let hello = try RFC_6068.Mailto.Header.subject("Hello")
        let shouted = try RFC_6068.Mailto.Header.subject("HELLO")

        #expect(hello != shouted)
    }
}
