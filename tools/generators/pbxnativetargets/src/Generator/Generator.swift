import Foundation
import GeneratorCommon
import OrderedCollections
import PBXProj

/// A type that generates and writes to disk the `PBXNativeTarget` `PBXProj`
/// partial, `PBXBuildFile` map files, and automatic `.xcscheme` files.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXNativeTarget` `PBXProj` partial, `PBXBuildFile` map
    /// files, and automatic `.xcscheme` files. Then it writes them to disk.
    func generate(arguments: Arguments) async throws {
        let consolidationMapEntries = try await ConsolidationMapEntry
            .decode(from: arguments.consolidationMap)

        let targetArguments = arguments.targetsArguments.toTargetArguments()
        let topLevelTargetAttributes = arguments.topLevelTargetAttributes
        let unitTestHosts = arguments.unitTestHosts

        let defaultXcodeConfiguration = arguments.defaultXcodeConfiguration
        let xcodeConfigurations: Set<String> = targetArguments.values
            .reduce(into: []) { xcodeConfigurations, targetArguments in
                xcodeConfigurations
                    .formUnion(targetArguments.xcodeConfigurations)
            }

        guard
            let shard = UInt8(arguments.consolidationMap.lastPathComponent)
        else {
            throw PreconditionError(message: #"""
Consolidation map (\#(arguments.consolidationMap)) basename is not formatted \#
correctly
"""#)
        }

        var buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier] = []
        var objects: [Object] = []

        // FIXME: Use a TaskGroup to process each entry in async (especially since each target reads a file)
        for entry in consolidationMapEntries {
            let key = entry.key

            var srcs: [[BazelPath]] = []
            var nonArcSrcs: [[BazelPath]] = []
            var hdrs: [[BazelPath]] = []
            var excludableFilesKeysWithValues: [(TargetID, Set<BazelPath>)] = []
            for id in key.sortedIds {
                let targetArguments = try targetArguments.value(
                    for: id,
                    context: "Target ID"
                )

                srcs.append(targetArguments.srcs)
                nonArcSrcs.append(targetArguments.nonArcSrcs)
                hdrs.append(targetArguments.hdrs)

                excludableFilesKeysWithValues.append(
                    (
                        id,
                        Set(
                            targetArguments.srcs +
                            targetArguments.nonArcSrcs +
                            targetArguments.hdrs
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
            let platformVariants = key.sortedIds.map { id in
                // We do a check above, so no need to do it again
                let targetArguments = targetArguments[id]!

                // For each platform variant calculate the set of files that are
                // "conditional", or not in the baseline files
                let conditionalFiles = excludableFiles[id]!
                    .subtracting(baselineFiles)

                allConditionalFiles.formUnion(conditionalFiles)

                let topLevelTargetAttributes = topLevelTargetAttributes[id]

                return Target.PlatformVariant(
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
                    buildSettingsFile:
                        targetArguments.buildSettingsFile,
                    linkParams: topLevelTargetAttributes?.linkParams,
                    hosts: [], //targetHosts[id] ?? [],
                    unitTestHost: topLevelTargetAttributes?.unitTestHost
                        .flatMap { unitTestHosts[$0] },
                    dSYMPathsBuildSetting:
                        targetArguments.dSYMPathsBuildSetting.isEmpty ?
                            nil : targetArguments.dSYMPathsBuildSetting
                )
            }

            let platforms = OrderedSet(
                platformVariants.map(\.platform).sorted()
            )

            let id = key.sortedIds.first!

            let aTopLevelTargetAttributes = topLevelTargetAttributes[id]
            let aTargetArguments = targetArguments[id]!

            let identifier = Identifiers.Targets.id(
                subIdentifier: entry.subIdentifier,
                name: entry.name
            )
            let productType = aTargetArguments.productType
            let productName = aTargetArguments.productName
            let productPath = entry.productPath
            let consolidatedInputs = Target.ConsolidatedInputs(
                srcs: consolidatePaths(srcs),
                nonArcSrcs: consolidatePaths(nonArcSrcs),
                hdrs: consolidatePaths(hdrs)
            )
            let hasLinkParams = aTopLevelTargetAttributes?.linkParams != nil

            let productBasename = String(
                productPath.split(separator: "/").last!
            )
            let productSubIdentifier = Identifiers.BuildFiles.productIdentifier(
                targetSubIdentifier: identifier.subIdentifier,
                productBasename: productBasename
            )
            buildFileSubIdentifiers.append(productSubIdentifier)

            var buildPhaseIdentifiers: [String] = []

            let isResourceBundle = productType == .resourceBundle

            if !isResourceBundle {
                let bazelIntegrationBuildPhase = environment
                    .createBazelIntegrationBuildPhaseObject(
                        subIdentifier: identifier.subIdentifier,
                        productType: productType
                    )
                buildPhaseIdentifiers
                    .append(bazelIntegrationBuildPhase.identifier)
                objects.append(bazelIntegrationBuildPhase)
            }

            if let createCompileDependenciesBuildPhase = environment
                .createCreateCompileDependenciesBuildPhaseObject(
                    subIdentifier: identifier.subIdentifier,
                    hasCParams: aTargetArguments.hasCParams,
                    hasCxxParams: aTargetArguments.hasCxxParams
                )
            {
                buildPhaseIdentifiers
                    .append(createCompileDependenciesBuildPhase.identifier)
                objects.append(createCompileDependenciesBuildPhase)
            }

            let hasCompilePhase = productType.hasCompilePhase

            let hasCompileStub = hasCompilePhase &&
                consolidatedInputs.srcs.isEmpty &&
                consolidatedInputs.nonArcSrcs.isEmpty

            if hasLinkParams {
                let createLinkDependenciesBuildPhase = environment
                    .createCreateLinkDependenciesBuildPhaseObject(
                        subIdentifier: identifier.subIdentifier,
                        hasCompileStub: hasCompileStub
                    )
                buildPhaseIdentifiers
                    .append(createLinkDependenciesBuildPhase.identifier)
                objects.append(createLinkDependenciesBuildPhase)
            }

            if !consolidatedInputs.hdrs.isEmpty {
                let hdrsSubIdentifiers = consolidatedInputs.hdrs.map { path in
                    return environment.createBuildFileSubIdentifier(
                        path,
                        type: .header,
                        shard: shard
                    )
                }
                buildFileSubIdentifiers.append(contentsOf: hdrsSubIdentifiers)

                let headersIdentifiers = hdrsSubIdentifiers
                    .map { Identifiers.BuildFiles.id(subIdentifier: $0) }

                let headersBuildPhase = environment
                    .createHeadersBuildPhaseObject(
                        subIdentifier: identifier.subIdentifier,
                        buildFileIdentifiers: headersIdentifiers
                    )
                buildPhaseIdentifiers.append(headersBuildPhase.identifier)
                objects.append(headersBuildPhase)
            }

            // FIXME: Exclude headers (probably in starlark?)
            let srcsSubIdentifiers = consolidatedInputs.srcs.map { path in
                return environment.createBuildFileSubIdentifier(
                    path,
                    type: .source,
                    shard: shard
                )
            }
            buildFileSubIdentifiers.append(contentsOf: srcsSubIdentifiers)

            let nonArcSrcsSubIdentifiers = consolidatedInputs.nonArcSrcs.map { path in
                return environment.createBuildFileSubIdentifier(
                    path,
                    type: .nonArcSource,
                    shard: shard
                )
            }
            buildFileSubIdentifiers.append(contentsOf: nonArcSrcsSubIdentifiers)

            if hasCompilePhase {
                let sourcesIdentifiers: [String]
                if hasCompileStub {
                    let compileStubSubIdentifier = Identifiers.BuildFiles
                        .compileStubSubIdentifier(
                            targetSubIdentifier: identifier.subIdentifier
                        )
                    buildFileSubIdentifiers.append(compileStubSubIdentifier)

                    sourcesIdentifiers = [
                        Identifiers.BuildFiles.id(
                            subIdentifier: compileStubSubIdentifier
                        ),
                    ]
                } else {
                    sourcesIdentifiers = (srcsSubIdentifiers +
                                          nonArcSrcsSubIdentifiers)
                    .map { Identifiers.BuildFiles.id(subIdentifier: $0) }
                }

                let sourcesBuildPhase = environment
                    .createSourcesBuildPhaseObject(
                        subIdentifier: identifier.subIdentifier,
                        buildFileIdentifiers: sourcesIdentifiers
                    )
                buildPhaseIdentifiers.append(sourcesBuildPhase.identifier)
                objects.append(sourcesBuildPhase)
            }

            let sharedBuildSettings = environment.calculateSharedBuildSettings(
                name: entry.name,
                label: entry.label,
                productType: productType,
                productName: productName,
                platforms: platforms,
                uiTestHostName: entry.uiTestHostName
            )

            var xcodeConfigurationBuildSettings: [
                String: [PlatformBuildSettings]
            ] = [:]
            for platformVariant in platformVariants {
                let buildSettings = try await environment
                    .calculatePlatformVariantBuildSettings(
                        productType: productType,
                        productPath: productPath,
                        platformVariant: platformVariant
                    )
                for xcodeConfiguration in platformVariant.xcodeConfigurations {
                    xcodeConfigurationBuildSettings[
                        xcodeConfiguration, default: []
                    ].append(
                        .init(
                            platform: platformVariant.platform,
                            conditionalFiles: platformVariant.conditionalFiles,
                            buildSettings: buildSettings
                        )
                    )
                }
            }

            var xcodeConfigurationAttributes = xcodeConfigurationBuildSettings
                .mapValues { platformBuildSettings in
                    let configurationBuildSettings = environment
                        .calculateXcodeConfigurationBuildSettings(
                            platformBuildSettings: platformBuildSettings,
                            allConditionalFiles: allConditionalFiles
                        )

                    return environment.createBuildSettingsAttribute(
                        buildSettings:
                            sharedBuildSettings + configurationBuildSettings
                    )
                }

            // For any missing configurations, have them equal to the default,
            // and if the default is one of the missing ones, choose the first
            // alphabetically
            let missingConfigurations = xcodeConfigurations.subtracting(
                Set(xcodeConfigurationAttributes.keys)
            )
            if !missingConfigurations.isEmpty {
                let attributes = xcodeConfigurationAttributes[
                    missingConfigurations.contains(defaultXcodeConfiguration) ?
                        xcodeConfigurationAttributes.keys.sorted().first! :
                        defaultXcodeConfiguration
                ]!
                for xcodeConfiguration in missingConfigurations {
                    xcodeConfigurationAttributes[xcodeConfiguration] =
                        attributes
                }
            }

            var configurationIndex: UInt8 = 0
            var configurationObjects: [Object] = []
            for (xcodeConfiguration, attribute) in
                    xcodeConfigurationAttributes.sorted(by: { $0.key < $1.key })
            {
                configurationObjects.append(
                    environment.createBuildConfigurationObject(
                        name: xcodeConfiguration,
                        index: configurationIndex,
                        subIdentifier: identifier.subIdentifier,
                        buildSettings: attribute
                    )
                )
                configurationIndex += 1
            }

            objects.append(contentsOf: configurationObjects)

            let configurationList = environment
                .createBuildConfigurationListObject(
                    name: entry.name,
                    subIdentifier: identifier.subIdentifier,
                    buildConfigurationIdentifiers:
                        configurationObjects.map(\.identifier),
                    defaultXcodeConfiguration: defaultXcodeConfiguration
                )
            objects.append(configurationList)

            objects.append(
                environment.createProductObject(
                    productType: productType,
                    productPath: productPath,
                    productBasename: productBasename,
                    subIdentifier: productSubIdentifier,
                    isAssociatedWithTarget:
                        productType.setsProductReference
                )
            )

            objects.append(
                environment.createTargetObject(
                    identifier: identifier,
                    productType: productType,
                    productName: productName,
                    productSubIdentifier: productSubIdentifier,
                    dependencySubIdentifiers: entry.dependencySubIdentifiers,
                    buildConfigurationListIdentifier:
                        configurationList.identifier,
                    buildPhaseIdentifiers: buildPhaseIdentifiers
                )
            )
        }

        let finishedBuildFileSubIdentifiers = buildFileSubIdentifiers
        let finishedElements = objects

        let writeTargetsTask = Task {
            try environment.write(
                environment.calculatePartial(
                    objects: finishedElements
                ),
                to: arguments.targetsOutputPath
            )
        }
        let writeBuildFileSubIdentifiersTask = Task {
            try environment.writeBuildFileSubIdentifiers(
                finishedBuildFileSubIdentifiers,
                to: arguments.buildFileSubIdentifiersOutputPath
            )
        }

        // Wait for all of the writes to complete
        try await writeTargetsTask.value
        try await writeBuildFileSubIdentifiersTask.value
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

private extension PBXProductType {
    var hasCompilePhase: Bool {
        switch self {
        case .messagesApplication,
             .watch2App,
             .watch2AppContainer,
             .resourceBundle:
            return false
        default:
            return true
        }
    }
}
