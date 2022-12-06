import PathKit
import XcodeProj

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let isResourceBundle: Bool
    let name: String
    let path: FilePath
    var additionalPaths: [FilePath]
    let executableName: String?

    /// Custom initializer for easier testing.
    init(
        type: PBXProductType,
        isResourceBundle: Bool = false,
        name: String,
        path: FilePath,
        additionalPaths: [FilePath] = [],
        executableName: String? = nil
    ) {
        self.type = type
        self.isResourceBundle = isResourceBundle
        self.name = name
        self.path = path
        self.additionalPaths = additionalPaths
        self.executableName = executableName
    }
}

extension Product {
    mutating func merge(_ other: Product) {
        additionalPaths.append(other.path)
        additionalPaths.append(contentsOf: other.additionalPaths)
    }

    func merging(_ other: Product) -> Product {
        var product = self
        product.merge(other)
        return product
    }
}
