@testable import generator

extension BazelLabel: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        do {
          try self.init(value)
        } catch {
            fatalError("invalid BazelLabel value: \(value)")
        }
    }
}
