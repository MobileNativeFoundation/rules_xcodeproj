public struct Label: Equatable, Hashable, CustomStringConvertible {
    public let repository: String
    public let package: String
    public let name: String
    public let description: String
}

extension Label {
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
        self.init(
            repository: parts.repository,
            package: parts.package,
            name: parts.name
        )
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

    init(repository: String = "", package: String, name: String) {
        self.repository = repository
        self.package = package
        self.name = name

        // Favor returning the shorthand form of the label,
        // e.g. for `@repo//foo/bar/wiz:wiz` return `@repo//foo/bar/wiz`,
        // for `@repo//foo/bar/wiz:baz` return `@repo//foo/bar/wiz:baz`,
        // for `@repo//foo/bar/wiz:bar/wiz` return `@repo//foo/bar/wiz:bar/wiz`.
        let canOmitName = !name.contains("/") && package.hasSuffix("/\(name)")
        let suffix = canOmitName ? "" : ":\(name)"
        description = "\(repository)//\(package)\(suffix)"
    }
}

// MARK: - ExpressibleByStringLiteral

extension Label: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        try! self.init(value)
    }
}
