extension RFC_6068.Mailto.Header {

    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case missingEquals(_ value: String)
        case emptyName(_ value: String)
        case invalidPercentEncoding(_ value: String)
    }
}

extension RFC_6068.Mailto.Header.Error {
    public var description: String {
        switch self {
        case .empty:
            return "Header field cannot be empty"

        case .missingEquals(let value):
            return "Header field must contain '=': '\(value)'"

        case .emptyName(let value):
            return "Header field name cannot be empty: '\(value)'"

        case .invalidPercentEncoding(let value):
            return "Invalid percent encoding in header: '\(value)'"
        }
    }
}
