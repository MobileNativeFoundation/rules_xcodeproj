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
        buildMode: BuildMode,
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

                // Set compile target id (used for "Compile File" command)
                merged.compileTarget = .init(id: source, name: merging.name)

                // Update product
                merged.product.merge(merging.product)

                // Update platform
                merged.platform = merging.platform

                // Update isSwift
                merged.isSwift = merging.isSwift

                // Merge build settings
                //
                // We remove `APPLICATION_EXTENSION_API_ONLY` from
                // `buildSettings`, as only the value from the top-level target
                // is valid
                var buildSettings = merging.buildSettings
                buildSettings
                    .removeValue(forKey: "APPLICATION_EXTENSION_API_ONLY")
                merged.buildSettings.merge(buildSettings) { _, r in r }

                // Update search paths
                merged.searchPaths.merge(merging.searchPaths)

                // Update modulemaps
                merged.modulemaps = merging.modulemaps

                // Update swiftmodules
                merged.swiftmodules = merging.swiftmodules

                // Update inputs
                merged.inputs.merge(merging.inputs)

                // Update linker inputs
                merged.linkerInputs.staticLibraries.remove(merging.product.path)
                merged.linkerInputs.forceLoad.remove(merging.product.path)

                // Update dependencies
                merged.dependencies.formUnion(merging.dependencies)

                // Update outputs
                merged.outputs.merge(merging.outputs)

                // Commit dest
                targets[destination] = merged
            }
        }

        // Update all targets
        for (id, target) in targets {
            // Dependencies
            for dependency in target.dependencies {
                if let newDependencies = targetMerges[dependency] {
                    targets[id]!.dependencies.remove(dependency)

                    // TODO: We only support one destination right now, but if
                    // that ever changes we need to fix this logic
                    for dependency in newDependencies {
                        guard dependency != id else {
                            continue
                        }
                        let (inserted, _) = targets[id]!.dependencies
                            .insert(dependency)

                        if buildMode == .xcode && inserted {
                            // TODO: When we move target merging into Starlark,
                            // we need to merge output groups as well, which is
                            // what this is currently working around (e.g.
                            // making sure framework Info.plists are generated).
                            targets[id]!.additionalSchemeTargets
                                .insert(dependency)
                        }
                    }
                }
            }
        }
    }
}
