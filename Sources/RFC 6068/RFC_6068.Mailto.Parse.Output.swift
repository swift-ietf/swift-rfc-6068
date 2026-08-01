extension RFC_6068.Mailto.Parse {
    public struct Output: Sendable {
        /// Raw address segments (comma-separated in the path component)
        public let addresses: [Input]
        /// Parsed header fields from the query component
        public let headers: [HeaderField]

        @inlinable
        public init(addresses: [Input], headers: [HeaderField]) {
            self.addresses = addresses
            self.headers = headers
        }
    }
}
