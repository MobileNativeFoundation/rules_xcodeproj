@testable import generator

extension BazelLabel: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)!
    }
}
