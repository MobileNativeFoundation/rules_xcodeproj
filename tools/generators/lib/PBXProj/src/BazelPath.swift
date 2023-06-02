import ArgumentParser
import Foundation

public struct BazelPath: Hashable {
    public var path: String
    public var isFolder: Bool

    public init(_ path: String, isFolder: Bool = false) {
        self.path = path
        self.isFolder = isFolder
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
