import PathKit
import XcodeProj

extension Generator {
    static func createProducts(
        in pbxProj: PBXProj,
        for consolidatedTargets: ConsolidatedTargets
    ) -> (Products, PBXGroup) {
        var products = Products()
        for (key, target) in consolidatedTargets.targets {
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
                path = defaultTarget.product.path
                    .flatMap { "bazel-out/\($0.path)" }
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
            children: products.byTarget.sortedLocalizedStandard(),
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

    private(set) var byTarget: [ConsolidatedTarget.Key: PBXFileReference] = [:]
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
    init(_ products: [ProductKeys: PBXFileReference]) {
        for (keys, product) in products {
            byTarget[keys.targetKey] = product
            for filePath in keys.filePaths {
                byFilePath[filePath] = product
            }
        }
    }
}
