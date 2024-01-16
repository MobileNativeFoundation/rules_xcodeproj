struct Target {
    let kind: RuleKind
    let label: Label
    // FIXME: Merge `singleAttrs` and `listAttrs`, add `.list` type
    var singleAttrs: [String: Attr]
    var listAttrs: [String: [Attr]]

    init(
        kind: RuleKind,
        label: Label,
        singleAttrs: [String: Attr] = [:],
        listAttrs: [String: [Attr]] = [:]
    ) {
        self.kind = kind
        self.label = label
        self.singleAttrs = singleAttrs
        self.listAttrs = listAttrs
    }
}

enum Attr {
    case string(String)
    case raw(String)
}

extension Attr: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Attr: CustomStringConvertible {
    var description: String {
        switch self {
        case let .string(value): return value.quoted
        case let .raw(value):
            return value
                .replacingOccurrences(of: #"\"#, with: #"\\"#)
                .replacingOccurrences(of: "|", with: #"\|"#)
                .replacingOccurrences(of: " ", with: #"\ "#)
        }
    }
}

extension Attr {
    mutating func append(_ value: String) {
        switch self {
        case let .string(existing): self = .string("\(existing)\(value)")
        case let .raw(existing): self = .raw("\(existing)\(value)")
        }
    }
}
