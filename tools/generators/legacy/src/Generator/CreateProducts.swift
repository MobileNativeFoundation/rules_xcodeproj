import OrderedCollections
import PathKit
import XcodeProj

extension Generator {
    static func createProducts(
        in pbxProj: PBXProj,
        for consolidatedTargets: ConsolidatedTargets
    ) -> (Products, PBXGroup) {
        var products = Products()
        for (key, target) in consolidatedTargets.targets.sorted(
            by: localizedStandardSort
        ) {
            let fileType: String?
            let name: String?
            let path: String?
            if target.product.type.setsAssociatedProduct {
                fileType = target.product.type.fileType
                name = nil
                path = target.product.basename
            } else {
                if target.product.type == .staticLibrary {
                    // This filetype is used to make the icon match what it
                    // would be if it was associated with a product (which it
                    // won't be)
                    fileType = "compiled.mach-o.dylib"
                } else {
                    fileType = target.product.type.fileType
                }

                // We can only show one product, so show the one for the default
                // target (i.e macOS, or Simulator, or arm64)
                let defaultTarget = target.sortedTargets.first!

                // We need to fix the path for deployment location products,
                // since we override `DEPLOYMENT_LOCATION` and
                // `BUILT_PRODUCTS_DIR` for them
                name = target.product.basename
                path = defaultTarget.product.path?.path.string
            }

            guard let path = path else {
                continue
            }

            let product = PBXFileReference(
                sourceTree: .buildProductsDir,
                name: name,
                explicitFileType: fileType,
                path: path,
                includeInIndex: false
            )
            pbxProj.add(object: product)
            products.add(
                product: product,
                for: .init(targetKey: key, filePaths: target.product.paths)
            )
        }

        let group = PBXGroup(
            children: products.byTarget.values.elements,
            sourceTree: .group,
            name: "Products"
        )
        pbxProj.add(object: group)
        pbxProj.rootObject?.productsGroup = group

        return (products, group)
    }
}

struct Products: Equatable {
    struct ProductKeys: Equatable, Hashable {
        let targetKey: ConsolidatedTarget.Key
        let filePaths: Set<FilePath>
    }

    private(set) var byTarget:
        OrderedDictionary<ConsolidatedTarget.Key, PBXFileReference> = [:]
    private(set) var byFilePath: [FilePath: PBXFileReference] = [:]

    mutating func add(
        product: PBXFileReference,
        for keys: ProductKeys
    ) {
        byTarget[keys.targetKey] = product
        for filePath in keys.filePaths {
            byFilePath[filePath] = product
        }
    }
}

extension Products {
    init(_ products: OrderedDictionary<ProductKeys, PBXFileReference>) {
        for (keys, product) in products {
            byTarget[keys.targetKey] = product
            for filePath in keys.filePaths {
                byFilePath[filePath] = product
            }
        }
    }
}

private func localizedStandardSort(
    lhs: (key: ConsolidatedTarget.Key, value: ConsolidatedTarget),
    rhs: (key: ConsolidatedTarget.Key, value: ConsolidatedTarget)
) -> Bool {
    let lhsTarget = lhs.value
    let rhsTarget = rhs.value

    guard
        let lhsBasename = lhsTarget.product.basename,
        let rhsBasename = rhsTarget.product.basename
    else {
        return false
    }

    let basenameCompare = lhsBasename.localizedStandardCompare(rhsBasename)
    guard basenameCompare == .orderedSame else {
        return basenameCompare == .orderedAscending
    }

    guard
        let lhsProductPath = lhsTarget.sortedTargets.first!.product.path,
        let rhsProductPath = rhsTarget.sortedTargets.first!.product.path
    else {
        return false
    }

    return lhsProductPath.path.string
        .localizedStandardCompare(rhsProductPath.path.string) ==
            .orderedAscending
}
