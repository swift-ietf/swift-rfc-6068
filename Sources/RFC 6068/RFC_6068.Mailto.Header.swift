// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-6068 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_6068.Mailto {
    /// A header field in a mailto URI
    ///
    /// Per RFC 6068 Section 2:
    /// ```
    /// hfield  = hfname "=" hfvalue
    /// hfname  = *qchar
    /// hfvalue = *qchar
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let header = try RFC_6068.Mailto.Header(ascii: "subject=Hello%20World".utf8)
    /// print(header.name)   // "subject"
    /// print(header.value)  // "Hello World"
    /// ```
    public struct Header: Sendable, Codable {
        /// The header field name, for example "subject", "body", or "cc"
        public let name: String

        /// The header field value (percent-decoded)
        public let value: String

        /// Creates a header WITHOUT validation
        ///
        /// Private to ensure all public construction goes through validation.
        private init(
            __unchecked: Void,
            name: String,
            value: String
        ) {
            self.name = name
            self.value = value
        }

        /// Creates a header field
        ///
        /// - Parameters:
        ///   - name: The header field name (e.g., "subject", "body")
        ///   - value: The header field value
        /// - Throws: `Error.emptyName` if the name is empty
        public init(name: String, value: String) throws(Error) {
            guard !name.isEmpty else {
                throw Error.emptyName("name cannot be empty")
            }
            self.init(
                // swift-linter:disable:next unchecked call site
                // REASON: same-package extension-init internal use — the emptiness invariant was just validated above.
                __unchecked: (),
                name: name,
                value: value
            )
        }
    }
}

// MARK: - Common Headers

extension RFC_6068.Mailto.Header {
    /// Creates a Subject header
    public static func subject(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "subject", value: value)
    }

    /// Creates a Body header
    public static func body(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "body", value: value)
    }

    /// Creates a Cc header
    public static func cc(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "cc", value: value)
    }

    /// Creates a Bcc header
    public static func bcc(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "bcc", value: value)
    }

    /// Creates a To header (additional recipients beyond path)
    public static func to(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "to", value: value)
    }

    /// Creates an In-Reply-To header
    public static func inReplyTo(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "in-reply-to", value: value)
    }
}

// MARK: - Serializable

extension RFC_6068.Mailto.Header: ASCII.Serializable, Binary.Serializable {
    /// Own `ASCII.Serializable` verb ([FAM-012]) — the RFC 6068
    /// `hfname "=" hfvalue` header field. `RFC_3986.percentEncode` is a
    /// UInt8-substrate leaf whose output is pure ASCII (`unreserved` / `%HH`);
    /// each octet is lifted to `ASCII.Code` (the same percent-encode algorithm,
    /// element type `Byte` -> `ASCII.Code`, no byte-detour). Output is identical
    /// to the Binary witness body (`serializeBytes`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {

        // Percent-encode name. The leaf yields `[UInt8]`; lift each octet to ASCII.Code.
        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(value.name.utf8), allowing: .mailto.qchar)
                .map { ASCII.Code(unchecked: Byte($0)) }
        )

        buffer.append(ASCII.Code.equalsSign)

        // Percent-encode value (same leaf, lifted to ASCII.Code).
        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(value.value.utf8), allowing: .mailto.qchar)
                .map { ASCII.Code(unchecked: Byte($0)) }
        )
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable `serialize(_:into:)` defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body (`hfname "=" hfvalue`, percent-encoded).
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ header: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {

        // Percent-encode name (RFC_3986 percentEncode returns [UInt8] — BSLI append bridges)
        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(header.name.utf8), allowing: .mailto.qchar)
        )

        buffer.append(ASCII.Code.equalsSign)

        // Percent-encode value (RFC_3986 percentEncode returns [UInt8] — BSLI append bridges)
        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(header.value.utf8), allowing: .mailto.qchar)
        )
    }
}

// MARK: - Parseable

extension RFC_6068.Mailto.Header: ASCII.Parseable {
    /// Creates a header field by validating `string`'s UTF-8 bytes.
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses a header field from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 6068 Section 2
    ///
    /// ```
    /// hfield  = hfname "=" hfvalue
    /// ```
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes, percent-encoded)
    /// - **Codomain**: RFC_6068.Mailto.Header (structured data)
    ///
    /// - Parameter bytes: The header field as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Swift.Collection>(
        ascii bytes: Bytes
    ) throws(Error)
    where Bytes.Element == Byte {
        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 6068 grammar is strict ASCII).
        let byteArray: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            byteArray = try [ASCII.Code](bytes)
        } catch {
            throw Error.invalidPercentEncoding(String(decoding: bytes, as: UTF8.self))
        }
        guard !byteArray.isEmpty else { throw Error.empty }

        // Find the '=' separator
        guard let equalsIndex = byteArray.firstIndex(of: ASCII.Code.equalsSign) else {
            throw Error.missingEquals(String(decoding: byteArray, as: UTF8.self))
        }

        // Bridge to UInt8 for RFC_3986.percentDecode (UInt8-substrate upstream API)
        let nameBytes = [UInt8](byteArray[..<equalsIndex])
        let valueBytes = [UInt8](byteArray[(equalsIndex + 1)...])

        guard !nameBytes.isEmpty else {
            throw Error.emptyName(String(decoding: byteArray, as: UTF8.self))
        }

        // Percent-decode both name and value
        let decodedName = RFC_3986.percentDecode(nameBytes)
        let decodedValue = RFC_3986.percentDecode(valueBytes)

        let name = String(decoding: decodedName, as: UTF8.self)
        let value = String(decoding: decodedValue, as: UTF8.self)

        try self.init(name: name, value: value)
    }
}

// MARK: - Protocol Conformances

extension RFC_6068.Mailto.Header: Swift.RawRepresentable {
    public typealias RawValue = String

    /// The header field's ASCII serialization as a `String` (computed; derived
    /// from serialization, not stored).
    public var rawValue: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_6068.Mailto.Header: CustomStringConvertible {
    /// The header field's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }
}

extension RFC_6068.Mailto.Header: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
        hasher.combine(value)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased() && lhs.value == rhs.value
    }
}
