extension RFC_6068.Mailto {

    public struct Header: Sendable {

        public let name: String

        public let value: String

        public init(name: String, value: String) throws(Error) {
            guard !name.isEmpty else {
                throw Error.emptyName(value)
            }
            self.name = name
            self.value = value
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

extension RFC_6068.Mailto.Header: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
        hasher.combine(value)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased() && lhs.value == rhs.value
    }
}
