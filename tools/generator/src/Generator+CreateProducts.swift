import PathKit
import XcodeProj

extension Generator {
    static func createProducts(
        in pbxProj: PBXProj,
        for targets: [TargetID: Target]
    ) -> (Products, PBXGroup) {
        var products = Products()
        for (id, target) in targets {
            let product = PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: target.product.type.fileType,
                path: target.product.path.lastComponent,
                includeInIndex: false
            )
            pbxProj.add(object: product)
            products.add(
                product: product,
                for: .init(target: id, path: target.product.path)
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
        let path: Path
    }

    private(set) var byTarget: [TargetID: PBXFileReference] = [:]
    private(set) var byPath: [Path: PBXFileReference] = [:]

    mutating func add(
        product: PBXFileReference,
        for keys: ProductKeys
    ) {
        byTarget[keys.target] = product
        byPath[keys.path] = product
    }
}

extension Products {
    init(_ products: [ProductKeys: PBXFileReference]) {
        for (keys, product) in products {
            byTarget[keys.target] = product
            byPath[keys.path] = product
        }
    }
}
