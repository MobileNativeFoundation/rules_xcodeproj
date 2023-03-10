import Foundation
import XcodeProj

private extension PBXFileElement {
    private static var cache: [String: String] = [:]
    private static let cacheLock = NSRecursiveLock()

    var sortOrder: Int {
        switch self {
        case is PBXVariantGroup:
            // Localized containers should be treated as files
            return 0
        case is XCVersionGroup:
            // Code Data containers should be treated as files
            return 0
        case is PBXGroup:
            return -1
        default:
            if let reference = self as? PBXFileReference {
                // Folders should be treated as groups
                return reference.lastKnownFileType == "folder" ? -1 : 0
            } else {
                return 0
            }
        }
    }

    var namePathSortString: String {
        Self.cacheLock.lock()
        defer {
            Self.cacheLock.unlock()
        }
        if let cached = Self.cache[uuid] {
            return cached
        }

        let parentNamePathSortString = parent?.namePathSortString ?? ""
        let ret = """
\(name ?? path ?? "")\t\(name ?? "")\t\(path ?? "")\t\(parentNamePathSortString)
"""
        Self.cache[uuid] = ret
        return ret
    }
}

extension Sequence {
    static func sortByLocalizedStandard(
        _ keyPath: KeyPath<Element, String>
    ) -> (
        _ lhs: Element,
        _ rhs: Element
    ) -> Bool {
        return { lhs, rhs in
            let l = lhs[keyPath: keyPath]
            let r = rhs[keyPath: keyPath]
            return l.localizedStandardCompare(r) == .orderedAscending
        }
    }

    func sortedLocalizedStandard(
        _ keyPath: KeyPath<Element, String>
    ) -> [Element] {
        return sorted(by: Self.sortByLocalizedStandard(keyPath))
    }
}

extension Sequence where Element: PBXFileElement {
    func sortedLocalizedStandard() -> [Element] {
        return sortedLocalizedStandard(\.namePathSortString)
    }
}

extension Sequence where Element == PBXBuildFile {
    func sortedLocalizedStandard() -> [Element] {
        return sortedLocalizedStandard(\.file!.namePathSortString)
    }
}

extension Array where Element: PBXFileElement {
    mutating func sortGroupedLocalizedStandard() {
        let fileSort = Self.sortByLocalizedStandard(\.namePathSortString)
        sort { lhs, rhs in
            let lhsSortOrder = lhs.sortOrder
            let rhsSortOrder = rhs.sortOrder
            if lhsSortOrder != rhsSortOrder {
                // Groups and folders before files
                return lhsSortOrder < rhsSortOrder
            } else {
                // Files alphabetically
                return fileSort(lhs, rhs)
            }
        }
        for element in self {
            if let group = element as? PBXGroup {
                group.children.sortGroupedLocalizedStandard()
            }
        }
    }
}

private struct PBXFileReferenceByTargetKey {
    let file: PBXFileReference
    let sortString: String

    init(_ element: (key: ConsolidatedTarget.Key, value: PBXFileReference)) {
        file = element.value
        sortString = "\(file.namePathSortString)\t\(element.key)"
    }
}

extension Dictionary
where Key == ConsolidatedTarget.Key, Value: PBXFileReference {
    func sortedLocalizedStandard() -> [PBXFileReference] {
        let sort = [PBXFileReferenceByTargetKey]
            .sortByLocalizedStandard(\.sortString)
        return map(PBXFileReferenceByTargetKey.init)
            .sorted(by: sort)
            .map(\.file)
    }
}
