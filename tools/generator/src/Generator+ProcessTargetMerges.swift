import PathKit

extension Generator {
    /// Attempts to merge targets.
    ///
    /// Bazel uses separate targets for compiling and bundling. So applications
    /// are minimally two targets, one for a static library and one for the
    /// application bundle. Xcode on the other hand uses a single target for
    /// bundles.
    ///
    /// We could choose to represent targets exactly like Bazel does, but this
    /// has a couple of drawbacks:
    ///
    /// - More targets and schemes will be represented in Xcode, which already
    ///   has poor scaling performance based on the number of targets.
    /// - SwiftUI Previews don't work for static libraries, so they wouldn't
    ///   work at all, as no code would be associated with the top level
    ///   targets in Xcode.
    ///
    /// - Parameters:
    ///   - targets: The universe of targets. These will be edited in place.
    ///   - targetMerges: A dictionary mapping target ids of targets
    ///     that should be merged to the target ids of the target they should
    ///     be merged into.
    static func processTargetMerges(
        targets: inout [TargetID: Target],
        targetMerges: [TargetID: Set<TargetID>]
    ) throws {
        for (source, destinations) in targetMerges {
            guard let merging = targets[source] else {
                throw PreconditionError(message: """
`targetMerges.key` (\(source)) references target that doesn't exist
""")
            }

            for destination in destinations {
                guard var merged = targets[destination] else {
                    throw PreconditionError(message: """
`potentialTargetMerges.value` (\(destination)) references target that doesn't \
exist
""")
                }

                // Remove src
                targets.removeValue(forKey: source)

                // Update Package Bin Dir
                // We take on the libraries bazel-out directory to prevent
                // issues with search paths that are calculated in Starlark.
                // We could instead push that calculation into the generator,
                // but that currently seems like too much work.
                merged.packageBinDir = merging.packageBinDir

                // Update isSwift
                merged.isSwift = merging.isSwift

                // Merge build settings
                merged.buildSettings["PRODUCT_MODULE_NAME"] =
                    merging.buildSettings["PRODUCT_MODULE_NAME"]
                
                let productName = merged.buildSettings["PRODUCT_NAME"]
                merged.buildSettings.merge(merging.buildSettings) { _, r in r }
                merged.buildSettings["PRODUCT_NAME"] = productName

                // Update search paths
                merged.searchPaths = merging.searchPaths

                // Update modulemaps
                merged.modulemaps = merging.modulemaps

                // Update swiftmodules
                merged.swiftmodules = merging.swiftmodules

                // Update inputs
                merged.inputs.merge(merging.inputs)

                // Update links
                merged.links.remove(merging.product.path)

                // Update dependencies
                merged.dependencies.formUnion(merging.dependencies)

                // Commit dest
                targets[destination] = merged
            }
        }

        // Update all targets
        for (id, target) in targets {
            // Dependencies
            for dependency in target.dependencies {
                if targetMerges[dependency] != nil {
                    targets[id]!.dependencies.remove(dependency)
                }
            }
        }
    }
}
