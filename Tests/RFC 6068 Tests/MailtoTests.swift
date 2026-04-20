// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-6068 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Testing

@testable import RFC_6068

@Suite("RFC 6068 Mailto Tests")
struct MailtoTests {

    @Test
    func `Parse simple mailto URI`() throws {
        let mailto = try RFC_6068.Mailto(ascii: "mailto:user@example.com".utf8)
        #expect(mailto.to.count == 1)
        #expect(mailto.to.first?.rawValue == "user@example.com")
        #expect(mailto.headers.isEmpty)
    }

    @Test
    func `Parse mailto with subject`() throws {
        let mailto = try RFC_6068.Mailto(ascii: "mailto:user@example.com?subject=Hello".utf8)
        #expect(mailto.to.count == 1)
        #expect(mailto.subject == "Hello")
    }

    @Test
    func `Parse mailto with percent-encoded subject`() throws {
        let mailto = try RFC_6068.Mailto(
            ascii: "mailto:user@example.com?subject=Hello%20World".utf8
        )
        #expect(mailto.subject == "Hello World")
    }

    @Test
    func `Parse mailto with multiple headers`() throws {
        let mailto = try RFC_6068.Mailto(
            ascii: "mailto:user@example.com?subject=Test&body=Hello".utf8
        )
        #expect(mailto.subject == "Test")
        #expect(mailto.body == "Hello")
    }

    @Test
    func `Parse mailto with multiple recipients`() throws {
        let mailto = try RFC_6068.Mailto(ascii: "mailto:user1@example.com,user2@example.com".utf8)
        #expect(mailto.to.count == 2)
    }

    @Test
    func `Parse mailto with no recipients (headers only)`() throws {
        let mailto = try RFC_6068.Mailto(ascii: "mailto:?subject=Test".utf8)
        #expect(mailto.to.isEmpty)
        #expect(mailto.subject == "Test")
    }

    @Test
    func `Serialize mailto URI`() throws {
        let addr = try RFC_5322.EmailAddress("user@example.com")
        let mailto = try RFC_6068.Mailto(
            to: [addr],
            headers: [try .subject("Hello")]
        )
        let serialized = String(mailto)
        #expect(serialized.hasPrefix("mailto:"))
        #expect(serialized.contains("user@example.com"))
        #expect(serialized.contains("subject=Hello"))
    }

    @Test
    func `Mailto is Hashable`() throws {
        let mailto1 = try RFC_6068.Mailto(ascii: "mailto:user@example.com".utf8)
        let mailto2 = try RFC_6068.Mailto(ascii: "mailto:user@example.com".utf8)
        #expect(mailto1 == mailto2)
        #expect(mailto1.hashValue == mailto2.hashValue)
    }

    @Test
    func `Header parsing`() throws {
        let header = try RFC_6068.Mailto.Header(ascii: "subject=Hello%20World".utf8)
        #expect(header.name == "subject")
        #expect(header.value == "Hello World")
    }

    @Test
    func `Header factory methods`() throws {
        let subject = try RFC_6068.Mailto.Header.subject("Test")
        #expect(subject.name == "subject")
        #expect(subject.value == "Test")

        let body = try RFC_6068.Mailto.Header.body("Content")
        #expect(body.name == "body")
        #expect(body.value == "Content")
    }

    @Test
    func `RFC 6068 example: simple mailto`() throws {
        // RFC 6068 Section 6.1
        let mailto = try RFC_6068.Mailto(ascii: "mailto:chris@example.com".utf8)
        #expect(mailto.to.count == 1)
        #expect(mailto.to.first?.rawValue == "chris@example.com")
    }

    @Test
    func `RFC 6068 example: with subject`() throws {
        // RFC 6068 Section 6.2
        let mailto = try RFC_6068.Mailto(
            ascii: "mailto:infobot@example.com?subject=current-issue".utf8
        )
        #expect(mailto.to.first?.rawValue == "infobot@example.com")
        #expect(mailto.subject == "current-issue")
    }

    @Test
    func `RFC 6068 example: with body`() throws {
        // RFC 6068 Section 6.3
        let mailto = try RFC_6068.Mailto(
            ascii: "mailto:infobot@example.com?body=send%20current-issue".utf8
        )
        #expect(mailto.body == "send current-issue")
    }

    @Test
    func `Error: empty input`() {
        #expect(throws: RFC_6068.Mailto.Error.self) {
            try RFC_6068.Mailto(ascii: "".utf8)
        }
    }

    @Test
    func `Error: missing scheme`() {
        #expect(throws: RFC_6068.Mailto.Error.self) {
            try RFC_6068.Mailto(ascii: "user@example.com".utf8)
        }
    }
}
