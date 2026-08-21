import ASCII_Serializer_Primitives
import Binary_Serializable_Primitives
import Parseable_ASCII_Primitives

extension RFC_3986.ByteSet {

    public enum Mailto {
    }

    public static var mailto: Mailto.Type { Mailto.self }
}

extension RFC_3986.ByteSet.Mailto {

    public static let someDelims = RFC_3986.ByteSet(
        ascii: "!$'()*+,;:@"
    )

    public static let qchar = RFC_3986.ByteSet.unreserved.union(someDelims)

    public static let addrSpec = RFC_3986.ByteSet.unreserved.union(
        RFC_3986.ByteSet(ascii: "@.")
    )
}

extension RFC_6068.Mailto {

    static func percentEncode<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) -> [UInt8] where Bytes.Element == UInt8 {
        RFC_3986.percentEncode(bytes, allowing: .mailto.addrSpec)
    }
}

extension RFC_6068.Mailto {

    static func serializeAddrSpec<Buffer: RangeReplaceableCollection>(
        _ address: RFC_5322.EmailAddress,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_5322.EmailAddress.LocalPart.serialize(address.localPart, into: &buffer)
        buffer.append(ASCII.Code.commercialAt)
        RFC_1123.Domain.serialize(address.domain, into: &buffer)
    }
}
