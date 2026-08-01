//
//  MailtoSerializationEquivalenceTests.swift
//  swift-rfc-6068
//
//  [FAM-012] composite re-cut guard. The Mailto `ASCII.Serializable` verb
//  (leaf-emitted scheme/delimiters, address percent-encode transform-over-verb-
//  output, and composed Header verb) MUST emit byte-identical output to the
//  `Binary.Serializable` witness (`serializeBytes`) for the percent-encode path.
//  Asserts the refactor invariant directly (ASCII output == Binary output), so no
//  expected string is hand-derived.
//

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
        // A display-name To address forces the addr-spec percent-encode branch
        // (space / `<` / `>` are outside `.mailto.addrSpec`); a header value with a
        // space and `&` forces the header percent-encode branch (composed via the
        // re-cut Header verb). Both bodies must emit byte-identical output.
        let address = try RFC_5322.EmailAddress("Jane Doe <jane@example.com>")
        let mailto = try RFC_6068.Mailto(
            to: [address],
            headers: [try RFC_6068.Mailto.Header(name: "subject", value: "Hello World & more")]
        )

        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = mailto.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_6068.Mailto.serialize(mailto, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
