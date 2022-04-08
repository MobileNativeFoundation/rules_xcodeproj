extension Target {
    mutating func merge(with other: Target) {
        // Update Package Bin Dir
        // We take on the libraries bazel-out directory to prevent
        // issues with search paths that are calculated in Starlark.
        // We could instead push that calculation into the generator,
        // but that currently seems like too much work.
        self.packageBinDir = other.packageBinDir

        // Update isSwift
        self.isSwift = other.isSwift

        // Merge build settings
        self.buildSettings["PRODUCT_MODULE_NAME"]
            = other.buildSettings["PRODUCT_MODULE_NAME"]
        self.buildSettings.merge(other.buildSettings) { l, _ in l }

        // Update search paths
        self.searchPaths = other.searchPaths

        // Update modulemaps
        self.modulemaps = other.modulemaps

        // Update swiftmodules
        self.swiftmodules = other.swiftmodules

        // Update inputs
        self.inputs.formUnion(other.inputs)

        // Update links
        self.links.remove(other.product.path)

        // Update dependencies
        self.dependencies.formUnion(other.dependencies)
    }
}
