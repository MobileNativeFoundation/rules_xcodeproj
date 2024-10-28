import ArgumentParser
import Foundation

public struct BazelPath: Hashable {
    public var path: String

    public init(_ path: String) {
        self.path = path
    }
}

// MARK: - Comparable

extension BazelPath: Comparable {
    public static func < (lhs: BazelPath, rhs: BazelPath) -> Bool {
        guard lhs.path == rhs.path else {
            return lhs.path < rhs.path
        }

        return false
    }
}

// MARK: - Decodable

extension BazelPath: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(String.self))
    }
}

// MARK: - ExpressibleByArgument

extension BazelPath: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}

// MARK: - ExpressibleByStringLiteral

extension BazelPath: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
