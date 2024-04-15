import OrderedCollections
import PBXProj

extension Generator {
    struct CreateXcodeConfigurations {
        private let calculatePlatformVariantBuildSettings:
            CalculatePlatformVariantBuildSettings
        private let calculateSharedBuildSettings: CalculateSharedBuildSettings
        private let calculateXcodeConfigurationBuildSettings:
            CalculateXcodeConfigurationBuildSettings
        private let createBuildConfigurationListObject:
            CreateBuildConfigurationListObject
        private let createBuildConfigurationObject:
            CreateBuildConfigurationObject
        private let createBuildSettingsAttribute: CreateBuildSettingsAttribute

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            calculatePlatformVariantBuildSettings:
                Generator.CalculatePlatformVariantBuildSettings,
            calculateSharedBuildSettings:
                Generator.CalculateSharedBuildSettings,
            calculateXcodeConfigurationBuildSettings:
                Generator.CalculateXcodeConfigurationBuildSettings,
            createBuildConfigurationListObject:
                Generator.CreateBuildConfigurationListObject,
            createBuildConfigurationObject:
                Generator.CreateBuildConfigurationObject,
            createBuildSettingsAttribute: CreateBuildSettingsAttribute,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.calculatePlatformVariantBuildSettings =
                calculatePlatformVariantBuildSettings
            self.calculateSharedBuildSettings = calculateSharedBuildSettings
            self.calculateXcodeConfigurationBuildSettings =
                calculateXcodeConfigurationBuildSettings
            self.createBuildConfigurationListObject =
                createBuildConfigurationListObject
            self.createBuildConfigurationObject = createBuildConfigurationObject
            self.createBuildSettingsAttribute = createBuildSettingsAttribute

            self.callable = callable
        }

        /// Creates the Xcode configuration `Object`s for a target.
        func callAsFunction(
            conditionalFiles: Set<BazelPath>,
            defaultXcodeConfiguration: String,
            identifier: Identifiers.Targets.Identifier,
            isBundle: Bool,
            label: BazelLabel,
            name: String,
            originalProductBasename: String,
            platformVariants: [Target.PlatformVariant],
            productName: String,
            productType: PBXProductType,
            uiTestHostName: String?,
            xcodeConfigurations: Set<String>
        ) async throws -> (
            configurationList: Object,
            configurationObjects: [Object]
        ) {
            return try await callable(
                /*conditionalFiles:*/ conditionalFiles,
                /*defaultXcodeConfiguration:*/ defaultXcodeConfiguration,
                /*identifier:*/ identifier,
                /*identifier:*/ isBundle,
                /*label:*/ label,
                /*name:*/ name,
                /*originalProductBasename:*/ originalProductBasename,
                /*platformVariants:*/ platformVariants,
                /*productName:*/ productName,
                /*productType:*/ productType,
                /*uiTestHostName:*/ uiTestHostName,
                /*xcodeConfigurations:*/ xcodeConfigurations,
                /*calculatePlatformVariantBuildSettings:*/
                    calculatePlatformVariantBuildSettings,
                /*calculateSharedBuildSettings:*/ calculateSharedBuildSettings,
                /*calculateXcodeConfigurationBuildSettings:*/
                    calculateXcodeConfigurationBuildSettings,
                /*createBuildConfigurationListObject:*/
                    createBuildConfigurationListObject,
                /*createBuildConfigurationObject:*/
                    createBuildConfigurationObject,
                /*createBuildSettingsAttribute:*/ createBuildSettingsAttribute
            )
        }
    }
}

// MARK: - CreateXcodeConfigurations.Callable

extension Generator.CreateXcodeConfigurations {
    typealias Callable = (
        _ conditionalFiles: Set<BazelPath>,
        _ defaultXcodeConfiguration: String,
        _ identifier: Identifiers.Targets.Identifier,
        _ isBundle: Bool,
        _ label: BazelLabel,
        _ name: String,
        _ originalProductBasename: String,
        _ platformVariants: [Target.PlatformVariant],
        _ productName: String,
        _ productType: PBXProductType,
        _ uiTestHostName: String?,
        _ xcodeConfigurations: Set<String>,
        _ calculatePlatformVariantBuildSettings:
            Generator.CalculatePlatformVariantBuildSettings,
        _ calculateSharedBuildSettings: Generator.CalculateSharedBuildSettings,
        _ calculateXcodeConfigurationBuildSettings:
            Generator.CalculateXcodeConfigurationBuildSettings,
        _ createBuildConfigurationListObject:
            Generator.CreateBuildConfigurationListObject,
        _ createBuildConfigurationObject:
            Generator.CreateBuildConfigurationObject,
        _ createBuildSettingsAttribute: CreateBuildSettingsAttribute
    ) async throws -> (
        configurationList: Object,
        configurationObjects: [Object]
    )

    static func defaultCallable(
        conditionalFiles: Set<BazelPath>,
        defaultXcodeConfiguration: String,
        identifier: Identifiers.Targets.Identifier,
        isBundle: Bool,
        label: BazelLabel,
        name: String,
        originalProductBasename: String,
        platformVariants: [Target.PlatformVariant],
        productName: String,
        productType: PBXProductType,
        uiTestHostName: String?,
        xcodeConfigurations: Set<String>,
        calculatePlatformVariantBuildSettings:
            Generator.CalculatePlatformVariantBuildSettings,
        calculateSharedBuildSettings: Generator.CalculateSharedBuildSettings,
        calculateXcodeConfigurationBuildSettings:
            Generator.CalculateXcodeConfigurationBuildSettings,
        createBuildConfigurationListObject:
            Generator.CreateBuildConfigurationListObject,
        createBuildConfigurationObject:
            Generator.CreateBuildConfigurationObject,
        createBuildSettingsAttribute: CreateBuildSettingsAttribute
    ) async throws -> (
        configurationList: Object,
        configurationObjects: [Object]
    ) {
        var objects: [Object] = []

        let sharedBuildSettings = calculateSharedBuildSettings(
            name: name,
            label: label,
            platforms: OrderedSet(
                platformVariants.map(\.platform).sorted()
            ),
            productType: productType,
            productName: productName,
            uiTestHostName: uiTestHostName
        )

        var xcodeConfigurationBuildSettings: [
            String: [PlatformBuildSettings]
        ] = [:]
        for platformVariant in platformVariants {
            let buildSettings =
                try await calculatePlatformVariantBuildSettings(
                    isBundle: isBundle,
                    originalProductBasename: originalProductBasename,
                    productType: productType,
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
                let configurationBuildSettings =
                    calculateXcodeConfigurationBuildSettings(
                        platformBuildSettings: platformBuildSettings,
                        allConditionalFiles: conditionalFiles
                    )

                return createBuildSettingsAttribute(
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
                createBuildConfigurationObject(
                    name: xcodeConfiguration,
                    index: configurationIndex,
                    subIdentifier: identifier.subIdentifier,
                    buildSettings: attribute
                )
            )
            configurationIndex += 1
        }
        objects.append(contentsOf: configurationObjects)

        let configurationList = createBuildConfigurationListObject(
            name: name,
            subIdentifier: identifier.subIdentifier,
            buildConfigurationIdentifiers:
                configurationObjects.map(\.identifier),
            defaultXcodeConfiguration: defaultXcodeConfiguration
        )
        objects.append(configurationList)

        return (configurationList, objects)
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

