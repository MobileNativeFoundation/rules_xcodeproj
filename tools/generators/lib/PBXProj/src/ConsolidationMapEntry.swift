import Foundation
import GeneratorCommon

public struct ConsolidationMapEntry: Equatable {
    public struct Key: Equatable, Hashable {
        public let sortedIds: [TargetID]

        public init(_ sortedIds: [TargetID]) {
            self.sortedIds = sortedIds
        }
    }

    public let key: Key
    public let label: BazelLabel
    public let productType: PBXProductType
    public let name: String
    public let productPath: String
    public let uiTestHostName: String?
    public let subIdentifier: Identifiers.Targets.SubIdentifier
    public let dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier]

    public init(
        key: Key,
        label: BazelLabel,
        productType: PBXProductType,
        name: String,
        productPath: String,
        uiTestHostName: String?,
        subIdentifier: Identifiers.Targets.SubIdentifier,
        dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier]
    ) {
        self.key = key
        self.label = label
        self.productType = productType
        self.name = name
        self.productPath = productPath
        self.uiTestHostName = uiTestHostName
        self.subIdentifier = subIdentifier
        self.dependencySubIdentifiers = dependencySubIdentifiers
    }
}

// MARK: - Comparable

extension ConsolidationMapEntry.Key: Comparable {
    public static func < (
        lhs: ConsolidationMapEntry.Key,
        rhs: ConsolidationMapEntry.Key
    ) -> Bool {
        for (lhsID, rhsID) in zip(lhs.sortedIds, rhs.sortedIds) {
            guard lhsID == rhsID else {
                return lhsID < rhsID
            }
        }

        guard lhs.sortedIds.count == rhs.sortedIds.count else {
            return lhs.sortedIds.count < rhs.sortedIds.count
        }

        return false
    }
}

// MARK: - Encode

extension ConsolidationMapEntry {
    private static let separator = Data([0x0a]) // Newline
    fileprivate static let subSeparator = Data([0x09]) // Tab
    private static let subSeparatorCharacter: Character = "\t"

    public static func encode(
        _ entires: [ConsolidationMapEntry],
        to url: URL
    ) throws {
        var data = Data()

        for entry in entires {
            entry.encode(into: &data)
        }

        try data.write(to: url)
    }

    private func encode(into data: inout Data) {
        data.append(Data(label.repository.utf8))
        data.append(Self.subSeparator)
        data.append(Data(label.package.utf8))
        data.append(Self.subSeparator)
        data.append(Data(label.name.utf8))
        data.append(Self.subSeparator)

        data.append(Data(productType.rawValue.utf8))
        data.append(Self.subSeparator)

        data.append(Data(name.utf8))
        data.append(Self.subSeparator)

        data.append(Data(productPath.utf8))
        data.append(Self.subSeparator)

        if let uiTestHostName {
            data.append(Data(uiTestHostName.utf8))
        }
        data.append(Self.subSeparator)

        key.encode(into: &data)

        subIdentifier.encode(into: &data)
        for dependencySubIdentifier in self.dependencySubIdentifiers {
            dependencySubIdentifier.encode(into: &data)
        }

        data.append(Self.separator)
    }
}

private extension ConsolidationMapEntry.Key {
    func encode(into data: inout Data) {
        for id in self.sortedIds {
            data.append(Data(id.rawValue.utf8))
            data.append(ConsolidationMapEntry.subSeparator)
        }
    }
}

private extension Identifiers.Targets.SubIdentifier {
    func encode(into data: inout Data) {
        data.append(Data(shard.utf8))
        data.append(Data(hash.utf8))
    }
}

// MARK: - Decode

extension ConsolidationMapEntry {
    public static func decode(
        from url: URL
    ) async throws -> [ConsolidationMapEntry] {
        do {
            var entries: [Self] = []
            for try await line in url.lines {
                entries.append(try .init(from: line, in: url))
            }
            return entries
        } catch {
            throw PreconditionError(message: """
"\(url.path)": \(error.localizedDescription)
""")
        }
    }

    private init(from line: String, in url: URL) throws {
        let components = line.split(
            separator: Self.subSeparatorCharacter,
            omittingEmptySubsequences: false
        )

        let subIdentifiersIndex = components.count - 1
        let subIdentifiersString = components[subIdentifiersIndex]
        let subIdentifierEndIndex = subIdentifiersString.index(
            subIdentifiersString.startIndex, offsetBy: 10
        )
        let subIdentifierRange =
            subIdentifiersString.startIndex ..< subIdentifierEndIndex
        let dependencySubIdentifiersRange =
            subIdentifierEndIndex ..< subIdentifiersString.endIndex

        guard
            let productType = PBXProductType(rawValue: String(components[3]))
        else {
            throw PreconditionError(message: #"""
"\#(url.path)": "\#(String(components[3]))" is an unknown product type
"""#)
        }

        let uiTestHostName = String(components[6])

        self.init(
            key: .init(from: components[7 ..< subIdentifiersIndex]),
            label: .init(
                repository: String(components[0]),
                package: String(components[1]),
                name: String(components[2])
            ),
            productType: productType,
            name: String(components[4]),
            productPath: String(components[5]),
            uiTestHostName: uiTestHostName.isEmpty ? nil : uiTestHostName,
            subIdentifier: .init(
                from: subIdentifiersString[subIdentifierRange]
            ),
            dependencySubIdentifiers:
                .init(from: subIdentifiersString[dependencySubIdentifiersRange])
        )
    }
}

private extension ConsolidationMapEntry.Key {
    init(from strings: ArraySlice<String.SubSequence>) {
        self.init(strings.lazy.map { TargetID(String($0)) })
    }
}

private extension Identifiers.Targets.SubIdentifier {
    init(from string: String.SubSequence) {
        let hashStartIndex = string.index(string.startIndex, offsetBy: 2)
        self.init(
            shard: String(string[string.startIndex ..< hashStartIndex]),
            hash: String(string[hashStartIndex ..< string.endIndex])
        )
    }
}

private extension Array where Element == Identifiers.Targets.SubIdentifier {
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
