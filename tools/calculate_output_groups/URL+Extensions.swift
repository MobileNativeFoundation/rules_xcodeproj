import Foundation
import ZippyJSON

extension URL {
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try ZippyJSONDecoder().decode(T.self, from: Data(contentsOf: self))
    }

    var modificationDate: Date? {
        try? resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    func newestDescendent(recursive: Bool = false, matching: (URL)->Bool={ _ in true }) -> URL? {
        let options: FileManager.DirectoryEnumerationOptions = recursive ? [] : [.skipsPackageDescendants, .skipsSubdirectoryDescendants]
        let enumerator = FileManager.default.enumerator(
            at: self,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: options.union(.skipsHiddenFiles)
        )!

        return enumerator.compactMap({ $0 as? URL }).filter(matching).max {
            guard
                let first = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                let second = try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            else { return false }

            return first < second
        }
    }
}
