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
        var mergedInto: [TargetID: TargetID] = [:]
        for (source, destinations) in targetMerges {
            for destination in destinations {
                mergedInto[destination] = source
            }
        }

        var fullyMerged: Set<TargetID> = []
        for (source, destinations) in targetMerges {
            guard let merging = targets[source] else {
                throw PreconditionError(message: """
`targetMerges.key` (\(source)) references target that doesn't exist
""")
            }

            fullyMerged.insert(source)

            for destination in destinations {
                guard var merged = targets[destination] else {
                    throw PreconditionError(message: """
`potentialTargetMerges.value` (\(destination)) references target that doesn't \
exist
""")
                }

                // Set compile target id (used for "Compile File" command)
                merged.compileTargetID = source

                // Update Package Bin Dir
                // We take on the libraries bazel-out directory to prevent
                // issues with search paths that are calculated in Starlark.
                // We could instead push that calculation into the generator,
                // but that currently seems like too much work.
                merged.packageBinDir = merging.packageBinDir

                // Update platform
                merged.platform = merging.platform

                // Update isSwift
                merged.isSwift = merging.isSwift

                // Merge build settings
                merged.buildSettings.merge(merging.buildSettings) { _, r in r }

                // Update search paths
                merged.searchPaths = merging.searchPaths

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
                merged.dependencies.remove(source)
                merged.dependencies.formUnion(merging.dependencies)

                if merged.product.type != .uiTestBundle,
                   let testHost = merged.testHost,
                   let mergedTestHostLibrary = mergedInto[testHost]
                {
                    merged.dependencies.remove(mergedTestHostLibrary)
                }

                // Update outputs
                merged.outputs.merge(merging.outputs)

                // Commit dest
                targets[destination] = merged
            }
        }

        // Remove targets that are fully merged
        for (id, target) in targets {
            if fullyMerged.contains(id) {
                continue
            }
            for dependency in target.dependencies {
                if targetMerges[dependency] != nil {
                    // Still used somewhere, so not fully merged
                    fullyMerged.remove(dependency)
                }
            }
        }
        for id in fullyMerged {
            targets.removeValue(forKey: id)
        }
    }
}
