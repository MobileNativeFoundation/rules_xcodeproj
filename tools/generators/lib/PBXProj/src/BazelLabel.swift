import ArgumentParser
import Foundation

public struct BazelLabel: Equatable, Hashable {
    public let repository: String
    public let package: String
    public let name: String
}

extension BazelLabel {
    static let rootSeparator = "//"
    static let nameSeparator = ":"
    static let packageSeparator = "/"

    public enum ParseError: Error {
        case missingOrTooManyRootSeparators
        case missingNameAndPackage
        case tooManyColons
    }

    public init(_ value: String) throws {
        let parts = try Self.parse(value)
        repository = parts.repository
        package = parts.package
        name = parts.name
    }

    private static func parse(
        _ value: String
    ) throws -> (repository: String, package: String, name: String) {
        // swiftlint:disable:previous large_tuple

        let rootParts = value.components(separatedBy: Self.rootSeparator)
        guard rootParts.count == 2 else {
            throw ParseError.missingOrTooManyRootSeparators
        }

        var repository = rootParts[0]
        if !repository.starts(with: "@") {
            // Support for `--noincompatible_unambiguous_label_stringification`,
            // and Bazel 5
            repository = "@\(repository)"
        }

        let packageAndNameParts = rootParts[1]
            .components(separatedBy: Self.nameSeparator)

        let package: String
        let name: String
        if packageAndNameParts.count == 2 {
            package = packageAndNameParts[0]
            name = packageAndNameParts[1]
        } else if packageAndNameParts.count == 1 {
            package = packageAndNameParts[0]
            guard package != "" else {
                throw ParseError.missingNameAndPackage
            }
            let packageParts = package
                .components(separatedBy: Self.packageSeparator)
            guard let lastPart = packageParts.last else {
                throw ParseError.missingNameAndPackage
            }
            name = lastPart
        } else {
            throw ParseError.tooManyColons
        }

        return (
            repository: repository,
            package: package,
            name: name
        )
    }
}

// MARK: - CustomStringConvertible

extension BazelLabel: CustomStringConvertible {
    public var description: String {
        return "\(repository)//\(package):\(name)"
    }
}

// MARK: - ExpressibleByArgument

extension BazelLabel: ExpressibleByArgument {
    public init?(argument: String) {
        do {
            try self.init(argument)
        } catch {
            return nil
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension BazelLabel: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        try! self.init(value)
    }
}
