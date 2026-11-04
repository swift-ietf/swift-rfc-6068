# swift-rfc-6068

Use this package when you need to build, read or write a `mailto:` URI. Start from `RFC_6068.Mailto`, which holds the recipients from the URI path and the header fields after `?` as `RFC_6068.Mailto.Header` values. If you only need an email address and no URI, use `RFC_5322.Mailbox` from swift-rfc-5322. For `Codable`, add the `RFC 6068 Foundation Integration` product.

## Laws

- Header names are case-insensitive and values are case-sensitive. `Subject=Hello` equals `subject=Hello` but not `subject=HELLO`.
- `RFC_6068.Mailto.subject` and `RFC_6068.Mailto.body` read the first header with that name.
- `RFC_6068.Mailto.allTo` is the path recipients followed by the recipients from `to` headers. `RFC_6068.Mailto.to` holds only the path recipients.
- `RFC_6068.Mailto.cc`, `RFC_6068.Mailto.bcc` and the header part of `RFC_6068.Mailto.allTo` read each header value as one mailbox. A value that isn't a mailbox is left out, with no error.
- A recipient keeps its display name in memory, but the URI form writes only its address. `Jane Doe <jane@example.com>` is written as `mailto:jane@example.com`.
- The scheme is read case-insensitively, so `MAILTO:` is accepted. Output always starts with `mailto:`.
- Parsing stops before whitespace, a control character, DEL or `#`, and leaves them unread. Reading a whole value with `RFC_6068.Mailto.init(ascii:)` fails on anything left over.
- Recipients are split on literal commas before they are percent-decoded, so an encoded comma (`%2C`) inside a quoted local part stays in one recipient.
- Header names and values are percent-decoded on input. On output they are percent-encoded except for unreserved characters and `!$'()*+,;:@`, so `&`, `=` and `?` in a value are always escaped. Addresses are encoded except for unreserved characters, `@` and `.`.
- Empty fields between ampersands are skipped. A field without `=` or with an empty name fails the whole URI.
- When parsing fails, the input is rewound to where the URI started.
- With `RFC 6068 Foundation Integration`, a mailto encodes as an object with `to` and `headers`, and a missing key decodes as empty. A header encodes as `name` and `value`, and an empty name fails to decode.
