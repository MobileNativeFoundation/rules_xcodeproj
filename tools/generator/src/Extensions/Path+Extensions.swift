import PathKit
import XcodeProj

extension String {
    /// Wraps the path in quotes if it needs it.
    var quoted: String {
        guard rangeOfCharacter(from: .whitespaces) != nil else {
            return self
        }
        return #""\#(self)""#
    }
}

// MARK: Decodable

extension Path: RawRepresentable, Decodable {
    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public var rawValue: String {
        return string
    }
}
