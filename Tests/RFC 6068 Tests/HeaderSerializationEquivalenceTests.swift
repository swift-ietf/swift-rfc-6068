import RFC_6068
import Testing

@Suite
struct `Header Serialization Equivalence` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Header Serialization Equivalence`.Unit {
    @Test
    func `ASCII verb output equals Binary witness output for the percent-encode path`() throws {

        let header = try RFC_6068.Mailto.Header(
            name: "a name",
            value: "Hello World & more"
        )

        let viaASCII: [Byte] = header.serialized

        var viaBinary: [Byte] = []
        RFC_6068.Mailto.Header.serialize(header, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
