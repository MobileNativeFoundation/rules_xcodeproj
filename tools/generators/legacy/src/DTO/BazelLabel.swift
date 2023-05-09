import Foundation

struct BazelLabel: Equatable, Hashable {
    let repository: String
    let package: String
    let name: String
}

extension BazelLabel {
    static let rootSeparator = "//"
    static let nameSeparator = ":"
    static let packageSeparator = "/"

    enum ParseError: Error {
        case missingOrTooManyRootSeparators
        case missingNameAndPackage
        case tooManyColons
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

    init(_ value: String) throws {
        let parts = try Self.parse(value)
        repository = parts.repository
        package = parts.package
        name = parts.name
    }

    init?(nilIfInvalid value: String) {
        do {
          try self.init(value)
        } catch {
            return nil
        }
    }
}

extension BazelLabel: CustomStringConvertible {
    var description: String {
        return "\(repository)//\(package):\(name)"
    }
}

extension BazelLabel: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)")
    }
}

extension BazelLabel: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        do {
            try self.init(value)
        } catch {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "invalid BazelLabel value: \(value)",
                underlyingError: error
            ))
        }
    }
}

extension Sequence where Element == BazelLabel {
    func sortedLocalizedStandard() -> [Element] {
        return sortedLocalizedStandard(\.description)
    }
}
