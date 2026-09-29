public import RFC_5322

extension RFC_6068 {

    public struct Mailto: Sendable {

        public let to: [RFC_5322.Mailbox]

        public let headers: [Header]

        public init(
            to: [RFC_5322.Mailbox] = [],
            headers: [Header] = []
        ) {
            self.to = to
            self.headers = headers
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

    public var allTo: [RFC_5322.Mailbox] {
        to + mailboxes(named: "to")
    }

    public var cc: [RFC_5322.Mailbox] {
        mailboxes(named: "cc")
    }

    public var bcc: [RFC_5322.Mailbox] {
        mailboxes(named: "bcc")
    }

    private func mailboxes(named name: String) -> [RFC_5322.Mailbox] {
        headers
            .filter { $0.name.lowercased() == name }
            .compactMap { header in
                do throws(RFC_5322.Mailbox.Error) {
                    return try RFC_5322.Mailbox(header.value)
                } catch {
                    return nil
                }
            }
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
