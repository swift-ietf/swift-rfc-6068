import Testing

@testable import RFC_6068

extension RFC_6068.Mailto {
    @Suite
    struct `Edge Case` {

        @Test
        func `Percent-encoded comma in quoted local part parses as a single addr-spec`() throws {

            let mailto = try RFC_6068.Mailto(
                ascii: Array("mailto:%22ab%2Ccd%22@example.com".utf8)
            )
            #expect(mailto.to.count == 1)

            #expect(mailto.to.first?.rawValue == "\"ab,cd\"@example.com")
        }

        @Test
        func
            `Literal comma still separates recipients when one addr-spec carries an encoded comma`()
            throws
        {
            let mailto = try RFC_6068.Mailto(
                ascii: Array("mailto:a@example.com,%22x%2Cy%22@example.org".utf8)
            )
            #expect(mailto.to.count == 2)

            #expect(mailto.to.first?.rawValue == "a@example.com")

            #expect(mailto.to.last?.rawValue == "\"x,y\"@example.org")
        }

        @Test
        func `Serialization of a display-name address emits only the addr-spec in the path`() throws
        {
            let address = try RFC_5322.EmailAddress("Jane Doe <jane@example.com>")
            let mailto = try RFC_6068.Mailto(to: [address])

            #expect(mailto.rawValue == "mailto:jane@example.com")
        }

        @Test
        func `Display-name address round-trips through serialization to the same addr-spec`() throws
        {
            let address = try RFC_5322.EmailAddress("Jane Doe <jane@example.com>")
            let mailto = try RFC_6068.Mailto(to: [address])

            let reparsed = try RFC_6068.Mailto(ascii: Array(mailto.rawValue.utf8))
            #expect(reparsed.to.count == 1)
            #expect(reparsed.to.first?.localPart == address.localPart)
            #expect(reparsed.to.first?.domain == address.domain)
        }
    }
}
