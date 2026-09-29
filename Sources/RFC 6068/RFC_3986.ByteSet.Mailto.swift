public import RFC_3986

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
