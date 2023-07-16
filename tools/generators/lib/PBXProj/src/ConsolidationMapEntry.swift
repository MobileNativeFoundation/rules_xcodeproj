import Foundation

public struct ConsolidationMapEntry: Equatable {
    public struct Key: Equatable, Hashable {
        public let sortedIds: [TargetID]

        public init(_ sortedIds: [TargetID]) {
            self.sortedIds = sortedIds
        }
    }

    public let key: Key
    public let name: String
    public let subIdentifier: Identifiers.Targets.SubIdentifier
    public let dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier]

    public init(
        key: Key,
        name: String,
        subIdentifier: Identifiers.Targets.SubIdentifier,
        dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier]
    ) {
        self.key = key
        self.name = name
        self.subIdentifier = subIdentifier
        self.dependencySubIdentifiers = dependencySubIdentifiers
    }
}

// MARK: - Encode

extension ConsolidationMapEntry {
    private static let separator = Data([0x0a]) // Newline
    fileprivate static let subSeparator = Data([0x09]) // Tab
    private static let subSeparatorCharacter: Character = "\t"

    public static func encode(
        entires: [ConsolidationMapEntry],
        to url: URL
    ) throws {
        var data = Data()

        for entry in entires {
            entry.encode(into: &data)
        }

        try data.write(to: url)
    }

    func encode(into data: inout Data) {
        data.append(name.data(using: .utf8)!)
        data.append(Self.subSeparator)

        key.encode(into: &data)

        subIdentifier.encode(into: &data)
        for dependencySubIdentifier in self.dependencySubIdentifiers {
            dependencySubIdentifier.encode(into: &data)
        }

        data.append(Self.separator)
    }
}

extension ConsolidationMapEntry.Key {
    func encode(into data: inout Data) {
        for id in self.sortedIds {
            data.append(id.rawValue.data(using: .utf8)!)
            data.append(ConsolidationMapEntry.subSeparator)
        }
    }
}

extension Identifiers.Targets.SubIdentifier {
    func encode(into data: inout Data) {
        data.append(shard.data(using: .utf8)!)
        data.append(hash.data(using: .utf8)!)
    }
}

// MARK: - Decode

extension ConsolidationMapEntry {
    public static func decode(
        from url: URL
    ) async throws -> [ConsolidationMapEntry] {
        var entries: [Self] = []
        for try await line in url.lines {
            entries.append(.init(from: line))
        }
        return entries
    }

    init(from line: String) {
        let components = line.split(separator: Self.subSeparatorCharacter)

        let subIdentifiersIndex = components.count - 1
        let subIdentifiersString = components[subIdentifiersIndex]
        let subIdentifierEndIndex = subIdentifiersString.index(
            subIdentifiersString.startIndex, offsetBy: 10
        )
        let subIdentifierRange =
            subIdentifiersString.startIndex ..< subIdentifierEndIndex
        let dependencySubIdentifiersRange =
            subIdentifierEndIndex ..< subIdentifiersString.endIndex

        self.init(
            key: .init(from: components[1 ..< subIdentifiersIndex]),
            name: String(components[0]),
            subIdentifier: .init(
                from: subIdentifiersString[subIdentifierRange]
            ),
            dependencySubIdentifiers:
                .init(from: subIdentifiersString[dependencySubIdentifiersRange])
        )
    }
}

extension ConsolidationMapEntry.Key {
    init(from strings: ArraySlice<String.SubSequence>) {
        self.init(strings.lazy.map { TargetID(String($0)) })
    }
}

extension Identifiers.Targets.SubIdentifier {
    init(from string: String.SubSequence) {
        let hashStartIndex = string.index(string.startIndex, offsetBy: 2)
        self.init(
            shard: String(string[string.startIndex ..< hashStartIndex]),
            hash: String(string[hashStartIndex ..< string.endIndex])
        )
    }
}

extension Array where Element == Identifiers.Targets.SubIdentifier {
    init(from string: String.SubSequence) {
        let count = string.count / 10
        self = (0 ..< count).map { index in
            let startIndex = string
                .index(string.startIndex, offsetBy: 10 * index)
            let endIndex = string.index(startIndex, offsetBy: 10)
            return Identifiers.Targets.SubIdentifier(
                from: string[startIndex ..< endIndex]
            )
        }
    }
}
