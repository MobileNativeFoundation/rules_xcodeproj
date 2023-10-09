import ArgumentParser
import Foundation

// Inspired by https://gist.github.com/mjdescy/a805b5b4c49ed79fb240d3886815d5a2
public struct SemanticVersion: Equatable, Hashable {
    static let maximumVersionPartCount = 3

    public let major: Int
    public let minor: Int
    public let patch: Int

    public init?(version: String) {
        var components = version.split(separator: ".").map { String($0) }
        let componentCount = components.count
        guard componentCount <= Self.maximumVersionPartCount else {
            return nil
        }

        let missingPartsCount = Self.maximumVersionPartCount - componentCount
        let missingParts = Array(repeating: "0", count: missingPartsCount)
        components.append(contentsOf: missingParts)

        self.init(
            major: components[0],
            minor: components[1],
            patch: components[2]
        )
    }

    public init?(major: String, minor: String, patch: String) {
        guard
            let majorAsInt = Int(major),
            let minorAsInt = Int(minor),
            let patchAsInt = Int(patch)
        else {
            return nil
        }

        self.init(major: majorAsInt, minor: minorAsInt, patch: patchAsInt)
    }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

extension SemanticVersion {
    /// Fully qualified version string.
    public var full: String {
        return "\(major).\(minor).\(patch)"
    }

    /// Output a version string that includes the major and minor values if the
    /// patch is `0`. Otherwise, output the fully qualified version string.
    public var pretty: String {
        guard patch != 0 else {
            return "\(major).\(minor)"
        }
        return full
    }
}

// MARK: - Comparable

extension SemanticVersion: Comparable {
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

// MARK: - CustomStringConvertible

extension SemanticVersion: CustomStringConvertible {
    public var description: String {
        return full
    }
}

// MARK: - Encodable

extension SemanticVersion: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(full)
    }
}

extension SemanticVersion: Decodable {
    public init(from decoder: Decoder) throws {
        let versionString = try decoder.singleValueContainer()
            .decode(String.self)
        guard let version = SemanticVersion(version: versionString) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid SemanticVersion: \(versionString)"
            ))
        }
        self = version
    }
}

// MARK: - ExpressibleByArgument

extension SemanticVersion: ExpressibleByArgument {
    public init?(argument: String) {
       self.init(version: argument)
    }
}

// MARK: - ExpressibleByStringLiteral

extension SemanticVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(version: value)!
    }
}
