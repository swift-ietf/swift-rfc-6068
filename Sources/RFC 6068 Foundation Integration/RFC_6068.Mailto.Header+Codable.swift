public import RFC_6068

extension RFC_6068.Mailto.Header: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            name: try container.decode(String.self, forKey: .name),
            value: try container.decode(String.self, forKey: .value)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }
}
