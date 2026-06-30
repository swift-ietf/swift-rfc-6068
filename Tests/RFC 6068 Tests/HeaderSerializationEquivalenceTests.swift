//
//  HeaderSerializationEquivalenceTests.swift
//  swift-rfc-6068
//
//  [FAM-012] composite re-cut guard. The Mailto.Header `ASCII.Serializable` verb
//  (the percent-encode leaf lifted to `ASCII.Code`) MUST emit byte-identical
//  output to the `Binary.Serializable` witness (`serializeBytes`) for the
//  percent-encode path. Asserts the refactor invariant directly (ASCII output ==
//  Binary output), so no expected string is hand-derived.
//

import RFC_6068
import Testing

@Suite
struct `Header Serialization Equivalence` {

    @Test
    func `ASCII verb output equals Binary witness output for the percent-encode path`() throws {
        // A name and value containing reserved characters (space, `&`) force the
        // percent-encode branch in both bodies — exactly the leaf transcribed into
        // the ASCII verb.
        let header = try RFC_6068.Mailto.Header(
            name: "a name",
            value: "Hello World & more"
        )

        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = header.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_6068.Mailto.Header.serialize(header, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
