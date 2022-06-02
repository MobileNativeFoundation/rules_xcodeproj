import OrderedCollections
import XcodeProj

/// Collects multiple Bazel targets (see `Target`) that can be represented by
/// a single Xcode target (see `PBXNativeTarget`).
///
/// In a Bazel build graph there might be multiple configurations of the
/// same label (e.g. macOS and iOS flavors of the same `swift_library`).
/// Xcode can represent these various configurations as a single target,
/// using build settings, and conditionals on build settings, to account
/// for the differences.
struct ConsolidatedTarget: Equatable {
    let name: String
    let label: String
    let product: ConsolidatedTargetProduct
    let isSwift: Bool
    let resourceBundles: Set<FilePath>
    let inputs: ConsolidatedTargetInputs
    let linkerInputs: ConsolidatedTargetLinkerInputs
    let outputs: ConsolidatedTargetOutputs

    /// The `Set` of `FilePath`s that each target references above the baseline.
    ///
    /// The baseline is all `FilePath`s that each target references. A reference
    /// in this case is anything that the `EXCLUDED_SOURCE_FILE_NAMES` and
    /// `INCLUDED_SOURCE_FILE_NAMES` apply to.
    let uniqueFiles: [TargetID: Set<FilePath>]

    let targets: [TargetID: Target]

    /// There are a couple places that want to use the "best" target for a
    /// value (i.e. the one most likely to be built), so we store the sorted
    /// targets as an optimization.
    let sortedTargets: [Target]
}

extension ConsolidatedTarget {
    init(targets: [TargetID: Target]) {
        self.targets = targets
        let aTarget = self.targets.first!.value

        name = aTarget.name
        label = aTarget.label
        product = ConsolidatedTargetProduct(
            name: aTarget.product.name,
            type: aTarget.product.type,
            basename: aTarget.product.path.path.lastComponent,
            paths: Set(targets.values.map(\.product.path))
        )
        isSwift = aTarget.isSwift

        var resourceBundles: Set<FilePath> = []
        targets.values.forEach { resourceBundles.formUnion($0.resourceBundles) }
        self.resourceBundles = resourceBundles

        sortedTargets = targets
            .sorted { lhs, rhs in
                return lhs.value.buildSettingConditional <
                    rhs.value.buildSettingConditional
            }
            .map { $1 }
        inputs = Self.consolidateInputs(targets: sortedTargets)
        linkerInputs = Self.consolidateLinkerInputs(targets: sortedTargets)

        var baselineFiles: Set<FilePath> = aTarget.allExcludableFiles
        for target in targets.values {
            baselineFiles.formIntersection(target.allExcludableFiles)
        }

        var uniqueFiles: [TargetID: Set<FilePath>] = [:]
        for (id, target) in targets {
            uniqueFiles[id] = target.allExcludableFiles
                .subtracting(baselineFiles)
        }
        self.uniqueFiles = uniqueFiles

        outputs = ConsolidatedTargetOutputs(
            hasOutputs: self.targets.values.contains { $0.outputs.hasOutputs },
            hasSwiftOutputs: self.targets.values
                .contains { $0.outputs.hasSwiftOutputs }
        )
    }

    private static func consolidateInputs(
        targets: [Target]
    ) -> ConsolidatedTargetInputs {
        return ConsolidatedTargetInputs(
            srcs: consolidateFiles(targets.map(\.inputs.srcs)),
            nonArcSrcs: consolidateFiles(targets.map(\.inputs.nonArcSrcs)),
            hdrs: targets.reduce(into: []) { all, target in
                return all.formUnion(target.inputs.hdrs)
            },
            resources: targets.reduce(into: []) { all, target in
                return all.formUnion(target.inputs.resources)
            }
        )
    }

    private static func consolidateLinkerInputs(
        targets: [Target]
    ) -> ConsolidatedTargetLinkerInputs {
        return ConsolidatedTargetLinkerInputs(
            staticFrameworks: consolidateFiles(
                targets.map(\.linkerInputs.staticFrameworks)
            ),
            dynamicFrameworks: consolidateFiles(
                targets.map(\.linkerInputs.dynamicFrameworks)
            )
        )
    }

    private static func consolidateFiles(_ files: [[FilePath]]) -> [FilePath] {
        guard !files.isEmpty else {
            return []
        }

        // First generate the baseline
        var baselineFiles = OrderedSet(files[0])
        for files in files {
            baselineFiles.formIntersection(files)
        }

        var consolidatedFiles = baselineFiles

        // For each array of `files`, insert them into `consolidatedFiles`,
        // preserving relative order
        for files in files {
            var consolidatedIdx = 0
            var filesIdx = 0
            while consolidatedIdx < consolidatedFiles.count &&
                    filesIdx < files.count
            {
                let file = files[filesIdx]
                filesIdx += 1

                guard consolidatedFiles[consolidatedIdx] != file else {
                    consolidatedIdx += 1
                    continue
                }

                if baselineFiles.contains(file) {
                    // We need to adjust out index based on where the file
                    // exists in the baseline
                    let foundIndex = consolidatedFiles.firstIndex(of: file)!
                    if foundIndex > consolidatedIdx {
                        consolidatedIdx = foundIndex + 1
                    }
                    continue
                }

                let (inserted, _) = consolidatedFiles.insert(
                    file,
                    at: consolidatedIdx
                )
                if inserted {
                    consolidatedIdx += 1
                }
            }

            if filesIdx < files.count {
                consolidatedFiles.append(contentsOf: files[filesIdx...])
            }
        }

        return consolidatedFiles.elements
    }
}

struct ConsolidatedTargetProduct: Equatable {
    let name: String
    let type: PBXProductType
    let basename: String
    let paths: Set<FilePath>
}

struct ConsolidatedTargetInputs: Equatable {
    let srcs: [FilePath]
    let nonArcSrcs: [FilePath]
    let hdrs: Set<FilePath>
    let resources: Set<FilePath>
}

struct ConsolidatedTargetLinkerInputs: Equatable {
    let staticFrameworks: [FilePath]
    let dynamicFrameworks: [FilePath]
}

struct ConsolidatedTargetOutputs: Equatable {
    let hasOutputs: Bool
    let hasSwiftOutputs: Bool
}

// MARK: - Private extensions

private extension Target {
    var allExcludableFiles: Set<FilePath> {
        var files = inputs.all
        files.formUnion(linkerInputs.allExcludableFiles)
        files.formUnion(resourceBundles)
        return files
    }
}

private extension LinkerInputs {
    var allExcludableFiles: Set<FilePath> {
        return Set(dynamicFrameworks)
    }
}
