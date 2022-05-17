import PathKit
import XcodeProj

extension Generator {
    static func createProducts(
        in pbxProj: PBXProj,
        for targets: [TargetID: Target]
    ) -> (Products, PBXGroup) {
        var products = Products()
        for (id, target) in targets {
            let fileType: String?
            let name: String?
            let path: String?
            if target.product.type.isLaunchable {
                fileType = target.product.type.fileType
                name = nil
                path = target.product.path.path.lastComponent
            } else {
                if target.product.type == .staticLibrary {
                    // This filetype is used to make the icon match what it
                    // would be if it was associated with a product (which it
                    // won't be)
                    fileType = "compiled.mach-o.dylib"
                } else {
                    fileType = target.product.type.fileType
                }

                // We need to fix the path for non-launchable products, since we
                // override `DEPLOYMENT_LOCATION` and `BUILT_PRODUCTS_DIR`
                // for them
                name = target.product.path.path.lastComponent
                path = "bazel-out/\(target.product.path.path)"
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
                for: .init(target: id, filePath: target.product.path)
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
        let target: TargetID
        let filePath: FilePath
    }

    private(set) var byTarget: [TargetID: PBXFileReference] = [:]
    private(set) var byFilePath: [FilePath: PBXFileReference] = [:]

    mutating func add(
        product: PBXFileReference,
        for keys: ProductKeys
    ) {
        byTarget[keys.target] = product
        byFilePath[keys.filePath] = product
    }
}

extension Products {
    init(_ products: [ProductKeys: PBXFileReference]) {
        for (keys, product) in products {
            byTarget[keys.target] = product
            byFilePath[keys.filePath] = product
        }
    }
}
