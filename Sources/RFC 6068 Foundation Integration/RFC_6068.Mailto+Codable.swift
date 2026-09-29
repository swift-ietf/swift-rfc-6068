public import RFC_6068
import RFC_5322
import RFC_5322_Foundation_Integration

extension RFC_6068.Mailto: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case to
        case headers
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            to: try container.decodeIfPresent([RFC_5322.Mailbox].self, forKey: .to) ?? [],
            headers: try container.decodeIfPresent([RFC_6068.Mailto.Header].self, forKey: .headers) ?? []
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try container.encode(headers, forKey: .headers)
    }
}
