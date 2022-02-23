/// A type-safe identifier for a target.
struct TargetID: Equatable, Hashable, Decodable {
    let rawValue: String

    /// Creates a `TargetID` from a given `String`.
    init(_ id: String) {
        self.rawValue = id
    }
}

// MARK: RawRepresentable

extension TargetID: RawRepresentable {
    init?(rawValue: String) {
        self.init(rawValue)
    }
}

// MARK: Comparable

extension TargetID: Comparable {
    static func < (lhs: TargetID, rhs: TargetID) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: CustomStringConvertible

extension TargetID: CustomStringConvertible {
    var description: String {
        return self.rawValue
    }
}
