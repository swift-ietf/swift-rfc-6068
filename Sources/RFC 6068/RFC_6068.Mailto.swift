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
public import Serializer_Primitives

extension RFC_6068 {
    /// A mailto URI as defined in RFC 6068
    ///
    /// The mailto URI scheme designates an Internet mailing address for
    /// the purposes of composing a message.
    ///
    /// ## ABNF Grammar (RFC 6068 Section 2)
    ///
    /// ```
    /// mailtoURI = "mailto:" [ to ] [ hfields ]
    /// to        = addr-spec *("," addr-spec)
    /// hfields   = "?" hfield *("&" hfield)
    /// hfield    = hfname "=" hfvalue
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple mailto
    /// let mailto = try RFC_6068.Mailto(ascii: "mailto:user@example.com".utf8)
    ///
    /// // With subject and body
    /// let mailto = try RFC_6068.Mailto(
    ///     ascii: "mailto:user@example.com?subject=Hello&body=World".utf8
    /// )
    /// ```
    public struct Mailto: Sendable, Codable {
        /// The recipient email addresses (from the path component)
        public let to: [RFC_5322.EmailAddress]

        /// The header fields (from the query component)
        public let headers: [Header]

        /// Creates a mailto URI WITHOUT validation
        ///
        /// Private to ensure all public construction goes through validation.
        private init(
            __unchecked: Void,
            to: [RFC_5322.EmailAddress],
            headers: [Header]
        ) {
            self.to = to
            self.headers = headers
        }

        /// Creates a new mailto URI
        ///
        /// - Parameters:
        ///   - to: The recipient email addresses
        ///   - headers: Optional header fields (subject, body, cc, etc.)
        /// - Throws: `Error` if validation fails
        public init(
            to: [RFC_5322.EmailAddress] = [],
            headers: [Header] = []
        ) throws(Error) {
            // Validation: must have at least one recipient or one header
            // (empty mailto: is technically valid per RFC 6068, so no validation needed currently)
            self.init(__unchecked: (), to: to, headers: headers)
        }
    }
}

// MARK: - Convenience Accessors

extension RFC_6068.Mailto {
    /// The subject header value, if present
    public var subject: String? {
        headers.first { $0.name.lowercased() == "subject" }?.value
    }

    /// The body header value, if present
    public var body: String? {
        headers.first { $0.name.lowercased() == "body" }?.value
    }

    /// Additional To addresses from headers (combined with path To addresses)
    public var allTo: [RFC_5322.EmailAddress] {
        var result = to
        for header in headers where header.name.lowercased() == "to" {
            if let addr = try? RFC_5322.EmailAddress(header.value) {
                result.append(addr)
            }
        }
        return result
    }

    /// Cc addresses from headers
    public var cc: [RFC_5322.EmailAddress] {
        headers
            .filter { $0.name.lowercased() == "cc" }
            .compactMap { try? RFC_5322.EmailAddress($0.value) }
    }

    /// Bcc addresses from headers
    public var bcc: [RFC_5322.EmailAddress] {
        headers
            .filter { $0.name.lowercased() == "bcc" }
            .compactMap { try? RFC_5322.EmailAddress($0.value) }
    }
}

// MARK: - Serializable

extension RFC_6068.Mailto: Serializable, ASCII.Serializable, Binary.Serializable {
    /// Canonical ASCII serializer for the RFC 6068 mailto URI.
    public static var serializer: Serializer_Primitives.Serializer.Pure<Self, [ASCII.Code]> {
        Serializer_Primitives.Serializer.Pure { mailto, buffer in
            var bytes: [Byte] = []
            serializeBytes(mailto, into: &bytes)
            buffer.append(contentsOf: bytes.map { ASCII.Code(unchecked: $0) })
        }
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable `serialize(_:into:)` defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body (`"mailto:" [ to ] [ "?" hfields ]`). The
    /// nested headers serialize via their own migrated family-Codable
    /// `.serialized` ([Byte]).
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ mailto: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        // Scheme
        buffer.append(contentsOf: "mailto:".utf8)

        // To addresses (percent-encoded, comma-separated)
        for (index, addr) in mailto.to.enumerated() {
            if index > 0 {
                buffer.append(ASCII.Code.comma)
            }
            // RFC_6068.Mailto.percentEncode returns [UInt8] — BSLI append bridges to Byte buffer
            buffer.append(contentsOf: RFC_6068.Mailto.percentEncode(Array(addr.rawValue.utf8)))
        }

        // Headers
        if !mailto.headers.isEmpty {
            buffer.append(ASCII.Code.questionMark)
            for (index, header) in mailto.headers.enumerated() {
                if index > 0 {
                    buffer.append(ASCII.Code.ampersand)
                }
                buffer.append(contentsOf: header.serialized)
            }
        }
    }
}

// MARK: - Parseable

extension RFC_6068.Mailto: ASCII.Parseable {
    /// Creates a mailto URI by validating `string`'s UTF-8 bytes.
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses a mailto URI from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 6068 Section 2
    ///
    /// ```
    /// mailtoURI = "mailto:" [ to ] [ hfields ]
    /// ```
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_6068.Mailto (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let mailto = try RFC_6068.Mailto(ascii: Array<Byte>("mailto:user@example.com".utf8))
    /// ```
    ///
    /// - Parameter bytes: The mailto URI as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Bridge to UInt8 once at entry — RFC_3986.percentDecode is UInt8-substrate,
        // so a single up-front conversion avoids per-element `.underlying` later.
        let byteArray = Array<UInt8>(bytes)
        guard !byteArray.isEmpty else { throw Error.empty }

        // Validate and strip scheme
        let scheme = Array("mailto:".utf8)
        guard byteArray.count >= scheme.count else {
            throw Error.missingScheme(String(decoding: byteArray, as: UTF8.self))
        }
        let schemeString = String(decoding: byteArray.prefix(scheme.count), as: UTF8.self)
            .lowercased()
        guard schemeString == "mailto:" else {
            throw Error.missingScheme(String(decoding: byteArray, as: UTF8.self))
        }
        let remainder = Array(byteArray.dropFirst(scheme.count))

        // Split into path and query components (UInt8 domain — RFC_3986 boundary)
        var pathBytes: [UInt8] = []
        var queryBytes: [UInt8] = []
        var inQuery = false
        for byte in remainder {
            if ASCII.Code(byte) == ASCII.Code.questionMark && !inQuery {
                inQuery = true
            } else if inQuery {
                queryBytes.append(byte)
            } else {
                pathBytes.append(byte)
            }
        }

        // Parse To addresses from path
        var toAddresses: [RFC_5322.EmailAddress] = []
        if !pathBytes.isEmpty {
            let decodedPath = RFC_3986.percentDecode(pathBytes)

            // Split on comma
            var addressStrings: [String] = []
            var current: [UInt8] = []
            for byte in decodedPath {
                if ASCII.Code(byte) == ASCII.Code.comma {
                    if !current.isEmpty {
                        addressStrings.append(String(decoding: current, as: UTF8.self))
                        current = []
                    }
                } else {
                    current.append(byte)
                }
            }
            if !current.isEmpty {
                addressStrings.append(String(decoding: current, as: UTF8.self))
            }

            for addrStr in addressStrings {
                // Trim whitespace
                var trimmed = Array(addrStr.utf8)
                while !trimmed.isEmpty,
                    let first = trimmed.first,
                    ASCII.Code(first) == ASCII.Code.space || ASCII.Code(first) == ASCII.Code.htab {
                    trimmed.removeFirst()
                }
                while !trimmed.isEmpty,
                    let last = trimmed.last,
                    ASCII.Code(last) == ASCII.Code.space || ASCII.Code(last) == ASCII.Code.htab {
                    trimmed.removeLast()
                }
                guard !trimmed.isEmpty else { continue }
                if let addr = try? RFC_5322.EmailAddress(String(decoding: trimmed, as: UTF8.self)) {
                    toAddresses.append(addr)
                }
            }
        }

        // Parse headers from query
        var headers: [Header] = []
        if !queryBytes.isEmpty {
            // Split on ampersand
            var headerFields: [[UInt8]] = []
            var currentField: [UInt8] = []
            for byte in queryBytes {
                if ASCII.Code(byte) == ASCII.Code.ampersand {
                    if !currentField.isEmpty {
                        headerFields.append(currentField)
                        currentField = []
                    }
                } else {
                    currentField.append(byte)
                }
            }
            if !currentField.isEmpty {
                headerFields.append(currentField)
            }

            for fieldBytes in headerFields {
                // Header(ascii:) expects Byte — bridge UInt8 → Byte
                if let header = try? Header(ascii: Array<Byte>(fieldBytes)) {
                    headers.append(header)
                }
            }
        }

        try self.init(to: toAddresses, headers: headers)
    }
}

// MARK: - Protocol Conformances

extension RFC_6068.Mailto: Swift.RawRepresentable {
    public typealias RawValue = String

    /// The mailto URI's ASCII serialization as a `String` (computed; derived
    /// from serialization, not stored).
    public var rawValue: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }

    public init?(rawValue: String) { try? self.init(rawValue) }
}

extension RFC_6068.Mailto: CustomStringConvertible {
    /// The mailto URI's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized.underlying, as: UTF8.self)
    }
}

extension RFC_6068.Mailto: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(to)
        hasher.combine(headers)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.to == rhs.to && lhs.headers == rhs.headers
    }
}

// MARK: - RFC 6068 ByteSets

extension RFC_3986.ByteSet {
    /// RFC 6068 character sets namespace
    public enum Mailto {
        /// RFC 6068 some-delims: `! $ ' ( ) * + , ; : @`
        ///
        /// Per RFC 6068 Section 2:
        /// ```
        /// some-delims = "!" / "$" / "'" / "(" / ")" / "*"
        ///             / "+" / "," / ";" / ":" / "@"
        /// ```
        ///
        /// This is a subset of RFC 3986 sub-delims that excludes `&` and `=`
        /// because those are delimiters in mailto URI query strings.
        public static let someDelims = RFC_3986.ByteSet(
            ascii: "!$'()*+,;:@"
        )

        /// RFC 6068 qchar = unreserved / pct-encoded / some-delims
        ///
        /// Per RFC 6068 Section 2:
        /// ```
        /// qchar = unreserved / pct-encoded / some-delims
        /// ```
        ///
        /// Characters allowed in mailto header field names and values.
        /// Excludes `&` and `=` which are query string delimiters.
        public static let qchar = RFC_3986.ByteSet.unreserved.union(someDelims)

        /// Characters allowed in mailto addr-spec path
        ///
        /// Per RFC 6068, the path component contains addr-spec values which
        /// need unreserved characters plus `@` and `.` unencoded.
        public static let addrSpec = RFC_3986.ByteSet.unreserved.union(
            RFC_3986.ByteSet(ascii: "@.")
        )
    }

    /// RFC 6068 character sets
    public static var mailto: Mailto.Type { Mailto.self }
}

// MARK: - Percent Encoding

extension RFC_6068.Mailto {
    /// Percent-encodes bytes for mailto URI path (addr-spec)
    ///
    /// Per RFC 6068 Section 2, characters not allowed in addr-spec must be encoded.
    static func percentEncode<Bytes: Collection>(
        _ bytes: Bytes
    ) -> [UInt8] where Bytes.Element == UInt8 {
        RFC_3986.percentEncode(bytes, allowing: .mailto.addrSpec)
    }
}
