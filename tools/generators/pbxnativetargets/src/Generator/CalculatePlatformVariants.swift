import OrderedCollections
import PBXProj

extension Generator {
    struct CalculatePlatformVariants {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates `Target.PlatformVariant`s for a target.
        func callAsFunction(
            ids: [TargetID],
            targetArguments: [TargetID: TargetArguments],
            topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes],
            unitTestHosts: [TargetID: Target.UnitTestHost]
        ) throws -> (
            platformVariants: [Target.PlatformVariant],
            conditionalFiles: Set<BazelPath>,
            consolidatedInputs: Target.ConsolidatedInputs
        ) {
            return try callable(
                /*ids:*/ ids,
                /*targetArguments:*/ targetArguments,
                /*topLevelTargetAttributes:*/ topLevelTargetAttributes,
                /*unitTestHosts:*/ unitTestHosts
            )
        }
    }
}

// MARK: - CalculatePlatformVariants.Callable

extension Generator.CalculatePlatformVariants {
    typealias Callable = (
        _ ids: [TargetID],
        _ targetArguments: [TargetID: TargetArguments],
        _ topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes],
        _ unitTestHosts: [TargetID: Target.UnitTestHost]
    ) throws -> (
        platformVariants: [Target.PlatformVariant],
        conditionalFiles: Set<BazelPath>,
        consolidatedInputs: Target.ConsolidatedInputs
    )

    static func defaultCallable(
        ids: [TargetID],
        targetArguments: [TargetID: TargetArguments],
        topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes],
        unitTestHosts: [TargetID: Target.UnitTestHost]
    ) throws -> (
        platformVariants: [Target.PlatformVariant],
        conditionalFiles: Set<BazelPath>,
        consolidatedInputs: Target.ConsolidatedInputs
    ) {
        var srcs: [[BazelPath]] = []
        var nonArcSrcs: [[BazelPath]] = []
        var librariesToLinkPaths: [[BazelPath]] = []
        var excludableFilesKeysWithValues: [(TargetID, Set<BazelPath>)] = []
        for id in ids {
            let targetArguments = try targetArguments.value(
                for: id,
                context: "Target ID"
            )

            srcs.append(targetArguments.srcs)
            nonArcSrcs.append(targetArguments.nonArcSrcs)
            librariesToLinkPaths.append(targetArguments.librariesToLinkPaths)

            excludableFilesKeysWithValues.append(
                (
                    id,
                    Set(
                        targetArguments.srcs +
                        targetArguments.nonArcSrcs
                    )
                )
            )
        }

        // For each platform variant, collect all files that can be excluded
        // with `EXCLUDED_SOURCE_FILE_NAMES`
        let excludableFiles = Dictionary(
            uniqueKeysWithValues: excludableFilesKeysWithValues
        )

        // Calculate the set of files that are the same for every platform
        // variant in the consolidated target
        let baselineFiles = excludableFiles.values.reduce(
            into: excludableFiles.first!.value
        ) { baselineFiles, targetExcludableFiles in
            baselineFiles.formIntersection(targetExcludableFiles)
        }

        var allConditionalFiles: Set<BazelPath> = []
        var platformVariants: [Target.PlatformVariant] = []
        for id in ids {
            // We do a check above, so no need to do it again
            let targetArguments = targetArguments[id]!

            // For each platform variant calculate the set of files that are
            // "conditional", or not in the baseline files
            let conditionalFiles = excludableFiles[id]!
                .subtracting(baselineFiles)

            allConditionalFiles.formUnion(conditionalFiles)

            let topLevelTargetAttributes = topLevelTargetAttributes[id]

            platformVariants.append(
                .init(
                    xcodeConfigurations: targetArguments.xcodeConfigurations,
                    id: id,
                    bundleID: topLevelTargetAttributes?.bundleID,
                    compileTargetIDs:
                        topLevelTargetAttributes?.compileTargetIDs,
                    packageBinDir: targetArguments.packageBinDir,
                    outputsProductPath:
                        topLevelTargetAttributes?.outputsProductPath,
                    productName: targetArguments.productName,
                    productBasename: targetArguments.productBasename,
                    moduleName: targetArguments.moduleName,
                    platform: targetArguments.platform,
                    osVersion: targetArguments.osVersion,
                    arch: targetArguments.arch,
                    executableName: topLevelTargetAttributes?.executableName,
                    conditionalFiles: conditionalFiles,
                    buildSettingsFromFile:
                        targetArguments.buildSettingsFromFile,
                    linkParams: topLevelTargetAttributes?.linkParams,
                    unitTestHost: topLevelTargetAttributes?.unitTestHost
                        .flatMap { unitTestHosts[$0] },
                    dSYMPathsBuildSetting:
                        targetArguments.dSYMPathsBuildSetting.isEmpty ?
                    nil : targetArguments.dSYMPathsBuildSetting,
                    librarySearchPaths: Set(targetArguments.librarySearchPaths)
                )
            )
        }

        let consolidatedInputs = Target.ConsolidatedInputs(
            srcs: consolidatePaths(srcs),
            nonArcSrcs: consolidatePaths(nonArcSrcs),
            librariesToLinkPaths: consolidatePaths(librariesToLinkPaths)
        )

        return (platformVariants, allConditionalFiles, consolidatedInputs)
    }
}

// FIXME: Extract and test?
private func consolidatePaths(_ paths: [[BazelPath]]) -> [BazelPath] {
    guard !paths.isEmpty else {
        return []
    }

    // First generate the baseline
    var baselinePaths = OrderedSet(paths[0])
    for paths in paths {
        baselinePaths.formIntersection(paths)
    }

    var consolidatedPaths = baselinePaths

    // For each array of `paths`, insert them into `consolidatedPaths`,
    // preserving relative order
    for paths in paths {
        var consolidatedIdx = 0
        var pathsIdx = 0
        while
            consolidatedIdx < consolidatedPaths.count, pathsIdx < paths.count
        {
            let path = paths[pathsIdx]
            pathsIdx += 1

            guard consolidatedPaths[consolidatedIdx] != path else {
                consolidatedIdx += 1
                continue
            }

            if baselinePaths.contains(path) {
                // We need to adjust our index based on where the file exists in
                // the baseline
                let foundIndex = consolidatedPaths.firstIndex(of: path)!
                if foundIndex > consolidatedIdx {
                    consolidatedIdx = foundIndex + 1
                }
                continue
            }

            let (inserted, _) = consolidatedPaths.insert(
                path,
                at: consolidatedIdx
            )
            if inserted {
                consolidatedIdx += 1
            }
        }

        if pathsIdx < paths.count {
            consolidatedPaths.append(contentsOf: paths[pathsIdx...])
        }
    }

    return consolidatedPaths.elements
}
