import ArgumentParser

public struct BazelPath: Hashable {
    public var path: String
    public var isFolder: Bool

    public init(_ path: String, isFolder: Bool = false) {
        self.path = path
        self.isFolder = isFolder
    }
}

// MARK: - ExpressibleByArgument

extension BazelPath: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
