extension RFC_6068.Mailto.Parse {
    public struct Output: Sendable {

        public let addresses: [Input]

        public let headers: [HeaderField]

        @inlinable
        public init(addresses: [Input], headers: [HeaderField]) {
            self.addresses = addresses
            self.headers = headers
        }
    }
}
