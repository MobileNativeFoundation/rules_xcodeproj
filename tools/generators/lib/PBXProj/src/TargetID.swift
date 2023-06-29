import ArgumentParser

/// A type-safe identifier for a target.
public struct TargetID: Equatable, Hashable, ExpressibleByArgument {
    public let rawValue: String

    /// Creates a `TargetID` from a given `String`.
    public init(_ id: String) {
        rawValue = id
    }
}

// MARK: - Comparable

extension TargetID: Comparable {
    public static func < (lhs: TargetID, rhs: TargetID) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomStringConvertible

extension TargetID: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension TargetID: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

// MARK: - RawRepresentable

extension TargetID: RawRepresentable {
    public init?(rawValue: String) {
        self.init(rawValue)
    }
}
