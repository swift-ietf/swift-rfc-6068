// Hoisted to non-generic module scope per [API-ERR-009]: `RFC_6068.Mailto.Parse<Input>`
// is generic, but these cases never use `Input` — nesting the error there risks an
// accidentally-generic `@error` SIL result under `-O -enable-default-cmo`
// (swiftlang/swift#89617). `RFC_6068.Mailto.Parse.Error` stays available as a
// typealias so the nested spelling keeps resolving.
public enum __RFC_6068_Mailto_Parse_Error: Swift.Error, Sendable, Equatable {
    case expectedMailtoScheme
}
