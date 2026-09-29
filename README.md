# swift-rfc-6068

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-ietf/swift-rfc-6068/workflows/CI/badge.svg)](https://github.com/swift-ietf/swift-rfc-6068/actions/workflows/ci.yml)

A Swift domain model of [RFC 6068](https://www.rfc-editor.org/rfc/rfc6068) - The 'mailto' URI Scheme.

## Overview

`RFC_6068.Mailto` holds the recipients of a mailto URI as `RFC_5322.Mailbox` values and its header fields as `RFC_6068.Mailto.Header` values, with accessors for the subject, body, to, cc and bcc headers. `RFC_3986.ByteSet.Mailto` carries the `some-delims`, `qchar` and addr-spec byte sets of the grammar.

Parsing and serializing the URI text form live in [swift-rfc-6068-coder](https://github.com/swift-ietf/swift-rfc-6068-coder) (`RFC_6068.Mailto.Coder`, `RFC_6068.Mailto.Header.Coder`). Apple Foundation `Codable` bridging lives in the `RFC 6068 Foundation Integration` product of this package.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-6068.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 6068", package: "swift-rfc-6068")
    ]
)
```

## Quick Start

```swift
import RFC_5322
import RFC_6068

let mailto = RFC_6068.Mailto(
    to: [try RFC_5322.Mailbox("user@example.com")],
    headers: [try .subject("Hello World"), try .body("Message content")]
)

mailto.to.first?.address  // "user@example.com"
mailto.subject            // "Hello World"
mailto.body               // "Message content"
mailto.cc                 // [RFC_5322.Mailbox]
mailto.allTo              // path recipients followed by the `to` header recipients
```

## Related Packages

| Package | Description |
|---------|-------------|
| [swift-rfc-6068-coder](https://github.com/swift-ietf/swift-rfc-6068-coder) | mailto URI coders |
| [swift-rfc-3986](https://github.com/swift-ietf/swift-rfc-3986) | URI Generic Syntax |
| [swift-rfc-3987](https://github.com/swift-ietf/swift-rfc-3987) | Internationalized Resource Identifiers (IRIs) |
| [swift-rfc-5322](https://github.com/swift-ietf/swift-rfc-5322) | Internet Message Format |
| [swift-rfc-2369](https://github.com/swift-ietf/swift-rfc-2369) | URLs for Mailing List Management |
| [swift-rfc-8058](https://github.com/swift-ietf/swift-rfc-8058) | One-Click Unsubscribe for List Email |

## License

This project is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE.md) for details.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.
