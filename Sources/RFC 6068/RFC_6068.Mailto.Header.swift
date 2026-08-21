public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_6068.Mailto {

    public struct Header: Sendable, Codable {

        public let name: String

        public let value: String

        private init(
            __unchecked: Void,
            name: String,
            value: String
        ) {
            self.name = name
            self.value = value
        }

        public init(name: String, value: String) throws(Error) {
            guard !name.isEmpty else {
                throw Error.emptyName("name cannot be empty")
            }
            self.init(

                __unchecked: (),
                name: name,
                value: value
            )
        }
    }
}

extension RFC_6068.Mailto.Header {

    public static func subject(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "subject", value: value)
    }

    public static func body(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "body", value: value)
    }

    public static func cc(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "cc", value: value)
    }

    public static func bcc(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "bcc", value: value)
    }

    public static func to(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "to", value: value)
    }

    public static func inReplyTo(
        _ value: String
    ) throws(Error) -> Self {
        try Self(name: "in-reply-to", value: value)
    }
}

extension RFC_6068.Mailto.Header: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {

        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(value.name.utf8), allowing: .mailto.qchar)
                .map { ASCII.Code(unchecked: Byte($0)) }
        )

        buffer.append(ASCII.Code.equalsSign)

        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(value.value.utf8), allowing: .mailto.qchar)
                .map { ASCII.Code(unchecked: Byte($0)) }
        )
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ header: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {

        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(header.name.utf8), allowing: .mailto.qchar)
        )

        buffer.append(ASCII.Code.equalsSign)

        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(header.value.utf8), allowing: .mailto.qchar)
        )
    }
}

extension RFC_6068.Mailto.Header: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(
        ascii bytes: Bytes
    ) throws(Error)
    where Bytes.Element == Byte {

        let byteArray: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            byteArray = try [ASCII.Code](bytes)
        } catch {
            throw Error.invalidPercentEncoding(String(decoding: bytes, as: UTF8.self))
        }
        guard !byteArray.isEmpty else { throw Error.empty }

        guard let equalsIndex = byteArray.firstIndex(of: ASCII.Code.equalsSign) else {
            throw Error.missingEquals(String(decoding: byteArray, as: UTF8.self))
        }

        let nameBytes = [UInt8](byteArray[..<equalsIndex])
        let valueBytes = [UInt8](byteArray[(equalsIndex + 1)...])

        guard !nameBytes.isEmpty else {
            throw Error.emptyName(String(decoding: byteArray, as: UTF8.self))
        }

        let decodedName = RFC_3986.percentDecode(nameBytes)
        let decodedValue = RFC_3986.percentDecode(valueBytes)

        let name = String(decoding: decodedName, as: UTF8.self)
        let value = String(decoding: decodedValue, as: UTF8.self)

        try self.init(name: name, value: value)
    }
}

extension RFC_6068.Mailto.Header: Swift.RawRepresentable {
    public typealias RawValue = String

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
