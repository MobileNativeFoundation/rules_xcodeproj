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
    ///   - potentialTargetMerges: A dictionary mapping target ids of targets
    ///     that should be merged to the target ids of the target they should
    ///     be merged into.
    ///   - requiredLinks: A set of paths that are linked into top level
    ///     targets. If any of the targets to be merged produce one of these
    ///     paths, then that merge won't happen and will be returned as invalid.
    ///
    /// - Returns: An array of `InvalidMerge` structs for any merges that
    ///   couldn't be performed.
    static func processTargetMerges(
        targets: inout [TargetID: Target],
        potentialTargetMerges: [TargetID: TargetID],
        requiredLinks: Set<Path>
    ) throws -> [InvalidMerge] {
        var validTargetMerges = potentialTargetMerges
        var invalidMerges: [InvalidMerge] = []
        for (src, dest) in potentialTargetMerges {
            guard let merging = targets[src] else {
                throw PreconditionError(message: """
`potentialTargetMerges.key` (\(src)) references target that doesn't exist
""")
            }

            guard !requiredLinks.contains(merging.product.path) else {
                validTargetMerges.removeValue(forKey: src)
                invalidMerges.append(InvalidMerge(src: src, dest: dest))
                continue
            }

            guard var merged = targets[dest] else {
                throw PreconditionError(message: """
`potentialTargetMerges.value` (\(dest)) references target that doesn't exist
""")
            }

            // Remove src
            targets.removeValue(forKey: src)

            // Merge build settings
            merged.buildSettings["PRODUCT_MODULE_NAME"] = merging.buildSettings["PRODUCT_MODULE_NAME"]
            merged.buildSettings.merge(merging.buildSettings) { lhs, _ in lhs }

            // Update sources
            merged.srcs = merging.srcs

            // Update links
            merged.links.remove(merging.product.path)

            // Update dependencies
            merged.dependencies.formUnion(merging.dependencies)

            // Commit dest
            targets[dest] = merged
        }

        // Update all targets
        for (id, target) in targets {
            // Dependencies
            for dependency in target.dependencies {
                if let dest = validTargetMerges[dependency] {
                    targets[id]!.dependencies.remove(dependency)
                    if id != dest {
                        targets[id]!.dependencies.insert(dest)
                    }
                }
            }
        }

        return invalidMerges
    }
}
