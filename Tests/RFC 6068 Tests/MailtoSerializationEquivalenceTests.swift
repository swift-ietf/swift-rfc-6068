import RFC_6068
import Testing

@Suite
struct `Mailto Serialization Equivalence` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Mailto Serialization Equivalence`.Unit {
    @Test
    func `ASCII verb output equals Binary witness output for the percent-encode path`() throws {

        let address = try RFC_5322.EmailAddress("Jane Doe <jane@example.com>")
        let mailto = try RFC_6068.Mailto(
            to: [address],
            headers: [try RFC_6068.Mailto.Header(name: "subject", value: "Hello World & more")]
        )

        let viaASCII: [Byte] = mailto.serialized

        var viaBinary: [Byte] = []
        RFC_6068.Mailto.serialize(mailto, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
