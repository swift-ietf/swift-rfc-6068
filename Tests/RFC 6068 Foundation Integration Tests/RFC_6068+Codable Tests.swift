import Foundation
import RFC_5322
import RFC_6068
import RFC_6068_Foundation_Integration
import Testing

@Suite
struct `RFC_6068+Codable Tests` {

    @Test
    func `a header codes as its name and value`() throws {
        let header = try RFC_6068.Mailto.Header.subject("Hello World")

        let encoded = try JSONEncoder().encode(header)

        #expect(try JSONDecoder().decode(RFC_6068.Mailto.Header.self, from: encoded) == header)
    }

    @Test
    func `a mailto codes as its recipients and headers`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("jane@example.com")],
            headers: [try .subject("Hello"), try .body("See you soon")]
        )

        let encoded = try JSONEncoder().encode(mailto)

        #expect(try JSONDecoder().decode(RFC_6068.Mailto.self, from: encoded) == mailto)
    }

    @Test
    func `a mailto without recipients or headers decodes from an empty object`() throws {
        let decoded = try JSONDecoder().decode(RFC_6068.Mailto.self, from: Data("{}".utf8))

        #expect(decoded == RFC_6068.Mailto())
    }
}
