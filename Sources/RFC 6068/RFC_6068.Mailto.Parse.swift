public import Parser

extension RFC_6068.Mailto {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_6068.Mailto.Parse {
    public typealias Error = __RFC_6068_Mailto_Parse_Error
}

extension RFC_6068.Mailto.Parse: Parser.`Protocol` {
    public typealias Failure = __RFC_6068_Mailto_Parse_Error
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {

        try Self._expectScheme(&input)

        var pathEnd = input.startIndex
        var questionMark: Input.Index? = nil
        var idx = input.startIndex
        while idx < input.endIndex {
            if input[idx] == 0x3F {
                questionMark = idx
                break
            }
            input.formIndex(after: &idx)
        }
        pathEnd = questionMark ?? input.endIndex

        var addresses: [Input] = []
        let pathSlice = input[input.startIndex..<pathEnd]
        if pathSlice.startIndex < pathSlice.endIndex {
            var segStart = pathSlice.startIndex
            var segIdx = pathSlice.startIndex
            while segIdx < pathSlice.endIndex {
                if pathSlice[segIdx] == 0x2C {
                    if segIdx > segStart {
                        addresses.append(pathSlice[segStart..<segIdx])
                    }
                    pathSlice.formIndex(after: &segIdx)
                    segStart = segIdx
                } else {
                    pathSlice.formIndex(after: &segIdx)
                }
            }
            if segIdx > segStart {
                addresses.append(pathSlice[segStart..<segIdx])
            }
        }

        var headers: [HeaderField] = []
        if let qm = questionMark {
            let queryStart = input.index(after: qm)
            let querySlice = input[queryStart..<input.endIndex]

            var fieldStart = querySlice.startIndex
            var fieldIdx = querySlice.startIndex
            while fieldIdx <= querySlice.endIndex {
                let atEnd = fieldIdx == querySlice.endIndex
                let atAmpersand = !atEnd && querySlice[fieldIdx] == 0x26

                if atEnd || atAmpersand {
                    let fieldSlice = querySlice[fieldStart..<fieldIdx]

                    var eqIdx = fieldSlice.startIndex
                    while eqIdx < fieldSlice.endIndex && fieldSlice[eqIdx] != 0x3D {
                        fieldSlice.formIndex(after: &eqIdx)
                    }
                    if eqIdx < fieldSlice.endIndex {
                        let name = fieldSlice[fieldSlice.startIndex..<eqIdx]
                        let valueStart = fieldSlice.index(after: eqIdx)
                        let value = fieldSlice[valueStart..<fieldSlice.endIndex]
                        headers.append(HeaderField(name: name, value: value))
                    }
                    if atAmpersand {
                        querySlice.formIndex(after: &fieldIdx)
                    }
                    fieldStart = fieldIdx
                }
                if !atEnd { querySlice.formIndex(after: &fieldIdx) }
                if atEnd { break }
            }
        }

        input = input[input.endIndex...]
        return Output(addresses: addresses, headers: headers)
    }

    @inlinable
    package static func _expectScheme(_ input: inout Input) throws(Failure) {

        let expected: [UInt8] = [0x6D, 0x61, 0x69, 0x6C, 0x74, 0x6F, 0x3A]
        var idx = input.startIndex
        for exp in expected {
            guard idx < input.endIndex else { throw .expectedMailtoScheme }
            let byte = input[idx]

            let lower = (byte >= 0x41 && byte <= 0x5A) ? (byte | 0x20) : byte
            guard lower == exp else { throw .expectedMailtoScheme }
            input.formIndex(after: &idx)
        }
        input = input[idx...]
    }
}
