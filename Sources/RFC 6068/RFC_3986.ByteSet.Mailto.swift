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

import ASCII_Serializer_Primitives
import Binary_Serializable_Primitives
import Parseable_ASCII_Primitives

// MARK: - RFC 6068 ByteSets

extension RFC_3986.ByteSet {
    /// RFC 6068 character sets namespace
    public enum Mailto {
    }

    /// RFC 6068 character sets
    public static var mailto: Mailto.Type { Mailto.self }
}

extension RFC_3986.ByteSet.Mailto {
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

// MARK: - Percent Encoding

extension RFC_6068.Mailto {
    /// Percent-encodes bytes for mailto URI path (addr-spec)
    ///
    /// Per RFC 6068 Section 2, characters not allowed in addr-spec must be encoded.
    static func percentEncode<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) -> [UInt8] where Bytes.Element == UInt8 {
        RFC_3986.percentEncode(bytes, allowing: .mailto.addrSpec)
    }
}

// MARK: - Addr-Spec Projection

extension RFC_6068.Mailto {
    /// Serializes only the addr-spec projection (`local-part "@" domain`) of an
    /// RFC 5322 address into the mailto path.
    ///
    /// RFC 6068 Section 2 restricts the path's `to` production to `addr-spec` —
    /// display names and angle brackets are not part of the grammar, so the full
    /// `RFC_5322.EmailAddress` name-addr verb must not be used here. Composes the
    /// upstream `LocalPart` / `RFC_1123.Domain` sub-part verbs rather than
    /// re-deriving the addr-spec grammar locally.
    static func serializeAddrSpec<Buffer: RangeReplaceableCollection>(
        _ address: RFC_5322.EmailAddress,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_5322.EmailAddress.LocalPart.serialize(address.localPart, into: &buffer)
        buffer.append(ASCII.Code.commercialAt)
        RFC_1123.Domain.serialize(address.domain, into: &buffer)
    }
}
