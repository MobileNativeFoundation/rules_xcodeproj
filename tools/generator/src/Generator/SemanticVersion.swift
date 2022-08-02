import Foundation

// Inspired by https://gist.github.com/mjdescy/a805b5b4c49ed79fb240d3886815d5a2
struct SemanticVersion: Equatable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init?(version: String) {
        let components = version.split(separator: ".")
        guard components.count == 3 else { return nil }

        self.init(major: String(components[0]),
                  minor: String(components[1]),
                  patch: String(components[2]))
    }

    public init?(major: String, minor: String, patch: String) {
        guard
            let majorAsInt = Int(major),
            let minorAsInt = Int(minor),
            let patchAsInt = Int(patch)
            else {
                return nil
        }

        self.init(major: majorAsInt,
                  minor: minorAsInt,
                  patch: patchAsInt)
    }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

extension SemanticVersion: Comparable {
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return (lhs.major < rhs.major)
            || (lhs.major == rhs.major && lhs.minor < rhs.minor)
            || (lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch < rhs.patch)
    }
}

extension SemanticVersion: CustomStringConvertible {
    public var description: String {
        return "\(major).\(minor).\(patch)"
    }
}
