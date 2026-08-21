public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_6068 {

    public struct Mailto: Sendable, Codable {

        public let to: [RFC_5322.EmailAddress]

        public let headers: [Header]

        private init(
            __unchecked: Void,
            to: [RFC_5322.EmailAddress],
            headers: [Header]
        ) {
            self.to = to
            self.headers = headers
        }

        public init(
            to: [RFC_5322.EmailAddress] = [],
            headers: [Header] = []
        ) throws(Error) {

            self.init(__unchecked: (), to: to, headers: headers)
        }
    }
}

extension RFC_6068.Mailto {

    public var subject: String? {
        headers.first { $0.name.lowercased() == "subject" }?.value
    }

    public var body: String? {
        headers.first { $0.name.lowercased() == "body" }?.value
    }

    public var allTo: [RFC_5322.EmailAddress] {
        var result = to
        for header in headers where header.name.lowercased() == "to" {
            do throws(RFC_5322.EmailAddress.Error) {
                result.append(try RFC_5322.EmailAddress(header.value))
            } catch {
            }
        }
        return result
    }

    public var cc: [RFC_5322.EmailAddress] {
        headers
            .filter { $0.name.lowercased() == "cc" }
            .compactMap { header in
                do throws(RFC_5322.EmailAddress.Error) {
                    return try RFC_5322.EmailAddress(header.value)
                } catch {
                    return nil
                }
            }
    }

    public var bcc: [RFC_5322.EmailAddress] {
        headers
            .filter { $0.name.lowercased() == "bcc" }
            .compactMap { header in
                do throws(RFC_5322.EmailAddress.Error) {
                    return try RFC_5322.EmailAddress(header.value)
                } catch {
                    return nil
                }
            }
    }
}

extension RFC_6068.Mailto: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {

        buffer.append(contentsOf: "mailto:".utf8.map { ASCII.Code(unchecked: Byte($0)) })

        for (index, addr) in value.to.enumerated() {
            if index > 0 {
                buffer.append(ASCII.Code.comma)
            }
            var addrBytes: [Byte] = []
            RFC_6068.Mailto.serializeAddrSpec(addr, into: &addrBytes)
            buffer.append(
                contentsOf: RFC_6068.Mailto.percentEncode(addrBytes.underlying)
                    .map { ASCII.Code(unchecked: Byte($0)) }
            )
        }

        if !value.headers.isEmpty {
            buffer.append(ASCII.Code.questionMark)
            for (index, header) in value.headers.enumerated() {
                if index > 0 {
                    buffer.append(ASCII.Code.ampersand)
                }
                RFC_6068.Mailto.Header.serialize(header, into: &buffer)
            }
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ mailto: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {

        buffer.append(contentsOf: "mailto:".utf8)

        for (index, addr) in mailto.to.enumerated() {
            if index > 0 {
                buffer.append(ASCII.Code.comma)
            }

            var addrBytes: [Byte] = []
            RFC_6068.Mailto.serializeAddrSpec(addr, into: &addrBytes)
            buffer.append(contentsOf: RFC_6068.Mailto.percentEncode(addrBytes.underlying))
        }

        if !mailto.headers.isEmpty {
            buffer.append(ASCII.Code.questionMark)
            for (index, header) in mailto.headers.enumerated() {
                if index > 0 {
                    buffer.append(ASCII.Code.ampersand)
                }
                RFC_6068.Mailto.Header.serialize(header, into: &buffer)
            }
        }
    }
}

extension RFC_6068.Mailto: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        let byteArray = [UInt8](bytes)
        guard !byteArray.isEmpty else { throw Error.empty }

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

        var toAddresses: [RFC_5322.EmailAddress] = []
        if !pathBytes.isEmpty {

            var encodedSegments: [[UInt8]] = []
            var current: [UInt8] = []
            for byte in pathBytes {
                if ASCII.Code(byte) == ASCII.Code.comma {
                    if !current.isEmpty {
                        encodedSegments.append(current)
                        current = []
                    }
                } else {
                    current.append(byte)
                }
            }
            if !current.isEmpty {
                encodedSegments.append(current)
            }

            let addressStrings = encodedSegments.map { segment in
                String(decoding: RFC_3986.percentDecode(segment), as: UTF8.self)
            }

            for addrStr in addressStrings {

                var trimmed = Array(addrStr.utf8)
                while !trimmed.isEmpty,
                    let first = trimmed.first,
                    ASCII.Code(first) == ASCII.Code.space || ASCII.Code(first) == ASCII.Code.htab
                {
                    trimmed.removeFirst()
                }
                while !trimmed.isEmpty,
                    let last = trimmed.last,
                    ASCII.Code(last) == ASCII.Code.space || ASCII.Code(last) == ASCII.Code.htab
                {
                    trimmed.removeLast()
                }
                guard !trimmed.isEmpty else { continue }
                do throws(RFC_5322.EmailAddress.Error) {
                    toAddresses.append(
                        try RFC_5322.EmailAddress(String(decoding: trimmed, as: UTF8.self))
                    )
                } catch {
                }
            }
        }

        var headers: [Header] = []
        if !queryBytes.isEmpty {

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

                do throws(Header.Error) {
                    headers.append(try Header(ascii: [Byte](fieldBytes)))
                } catch {
                }
            }
        }

        try self.init(to: toAddresses, headers: headers)
    }
}

extension RFC_6068.Mailto: Swift.RawRepresentable {
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

extension RFC_6068.Mailto: CustomStringConvertible {

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
