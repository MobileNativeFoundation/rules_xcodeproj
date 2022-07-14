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

    init?(_ value: String) {
        let rootParts = value.components(separatedBy: Self.rootSeparator)
        guard rootParts.count == 2 else {
            return nil
        }

        let repository = rootParts[0]
        let packageAndNameParts = rootParts[1].components(separatedBy: Self.nameSeparator)

        let package: String
        let name: String
        if packageAndNameParts.count == 2 {
            package = packageAndNameParts[0]
            name = packageAndNameParts[1]
        } else if packageAndNameParts.count == 1 {
            package = packageAndNameParts[0]
            guard package != "" else {
              return nil
            }
            let packageParts = package.components(separatedBy: Self.packageSeparator)
            guard let lastPart = packageParts.last else {
              return nil
            }
            name = lastPart
        } else {
            return nil
        }

        self.init(
            repository: repository,
            package: package,
            name: name
        )
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
        // TODO: Switch to throwing an error
        self.init(value)!
    }
}
