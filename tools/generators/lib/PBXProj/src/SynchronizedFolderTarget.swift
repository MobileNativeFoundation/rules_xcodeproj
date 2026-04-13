import Foundation

public struct SynchronizedFolderTarget: Codable, Equatable {
    public let folderPath: BazelPath
    public let targetIdentifier: String
    public let targetName: String
    public let includedPaths: [BazelPath]
    public let excludedPaths: [BazelPath]

    public init(
        folderPath: BazelPath,
        targetIdentifier: String,
        targetName: String,
        includedPaths: [BazelPath],
        excludedPaths: [BazelPath]
    ) {
        self.folderPath = folderPath
        self.targetIdentifier = targetIdentifier
        self.targetName = targetName
        self.includedPaths = includedPaths
        self.excludedPaths = excludedPaths
    }
}

public extension Array where Element == SynchronizedFolderTarget {
    static func decode(from url: URL) async throws -> Self {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Self.self, from: data)
    }

    func encode(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: url)
    }
}
