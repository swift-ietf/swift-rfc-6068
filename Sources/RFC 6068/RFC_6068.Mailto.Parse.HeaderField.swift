extension RFC_6068.Mailto.Parse {
    public struct HeaderField: Sendable {
        public let name: Input
        public let value: Input

        @inlinable
        public init(name: Input, value: Input) {
            self.name = name
            self.value = value
        }
    }
}
