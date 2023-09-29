import OrderedCollections
import PBXProj

extension Generator {
    struct CreateTarget {
        private let calculatePlatformVariants: CalculatePlatformVariants
        private let createBuildPhases: CreateBuildPhases
        private let createProductObject: CreateProductObject
        private let createTargetObject: CreateTargetObject
        private let createXcodeConfigurations: CreateXcodeConfigurations

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            calculatePlatformVariants: CalculatePlatformVariants,
            createBuildPhases: CreateBuildPhases,
            createProductObject: CreateProductObject,
            createTargetObject: CreateTargetObject,
            createXcodeConfigurations: CreateXcodeConfigurations,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.calculatePlatformVariants = calculatePlatformVariants
            self.createBuildPhases = createBuildPhases
            self.createProductObject = createProductObject
            self.createTargetObject = createTargetObject
            self.createXcodeConfigurations = createXcodeConfigurations

            self.callable = callable
        }

        /// Creates a target and all of its related elements.
        func callAsFunction(
            consolidationMapEntry entry: ConsolidationMapEntry,
            defaultXcodeConfiguration: String,
            shard: UInt8,
            targetArguments: [TargetID: TargetArguments],
            topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes],
            unitTestHosts: [TargetID: Target.UnitTestHost],
            xcodeConfigurations: Set<String>
        ) async throws -> (
            buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier],
            objects: [Object]
        ) {
            return try await callable(
                /*consolidationMapEntry:*/ entry,
                /*defaultXcodeConfiguration:*/ defaultXcodeConfiguration,
                /*shard:*/ shard,
                /*targetArguments:*/ targetArguments,
                /*topLevelTargetAttributes:*/ topLevelTargetAttributes,
                /*unitTestHosts:*/ unitTestHosts,
                /*xcodeConfigurations:*/ xcodeConfigurations,
                /*calculatePlatformVariants:*/ calculatePlatformVariants,
                /*createBuildPhases:*/ createBuildPhases,
                /*createProductObject:*/ createProductObject,
                /*createTargetObject:*/ createTargetObject,
                /*createXcodeConfigurations:*/ createXcodeConfigurations
            )
        }
    }
}

// MARK: - CreateTarget.Callable

extension Generator.CreateTarget {
    typealias Callable = (
        _ consolidationMapEntry: ConsolidationMapEntry,
        _ defaultXcodeConfiguration: String,
        _ shard: UInt8,
        _ targetArguments: [TargetID: TargetArguments],
        _ topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes],
        _ unitTestHosts: [TargetID: Target.UnitTestHost],
        _ xcodeConfigurations: Set<String>,
        _ calculatePlatformVariants: Generator.CalculatePlatformVariants,
        _ createBuildPhases: Generator.CreateBuildPhases,
        _ createProductObject: Generator.CreateProductObject,
        _ createTargetObject: Generator.CreateTargetObject,
        _ createXcodeConfigurations: Generator.CreateXcodeConfigurations
    ) async throws -> (
        buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier],
        objects: [Object]
    )

    static func defaultCallable(
        consolidationMapEntry entry: ConsolidationMapEntry,
        defaultXcodeConfiguration: String,
        shard: UInt8,
        targetArguments: [TargetID: TargetArguments],
        topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes],
        unitTestHosts: [TargetID: Target.UnitTestHost],
        xcodeConfigurations: Set<String>,
        calculatePlatformVariants: Generator.CalculatePlatformVariants,
        createBuildPhases: Generator.CreateBuildPhases,
        createProductObject: Generator.CreateProductObject,
        createTargetObject: Generator.CreateTargetObject,
        createXcodeConfigurations: Generator.CreateXcodeConfigurations
    ) async throws -> (
        buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier],
        objects: [Object]
    ) {
        let ids = entry.key.sortedIds
        let id = ids.first!
        let aTargetArguments = targetArguments[id]!
        let productType = aTargetArguments.productType
        let productName = aTargetArguments.productName
        let productPath = entry.productPath
        let isBundle = productType.isBundle
        let setsProductReference = productType.setsProductReference

        let identifier = Identifiers.Targets.id(
            subIdentifier: entry.subIdentifier,
            name: entry.name
        )
        let productSubIdentifier = Identifiers.BuildFiles.productIdentifier(
            targetSubIdentifier: identifier.subIdentifier,
            productBasename: String(productPath.split(separator: "/").last!)
        )

        let (
            platformVariants,
            conditionalFiles,
            consolidatedInputs
        ) = try calculatePlatformVariants(
            ids: ids,
            targetArguments: targetArguments,
            topLevelTargetAttributes: topLevelTargetAttributes,
            unitTestHosts: unitTestHosts
        )

        let (
            buildPhases,
            buildFileObjects,
            buildPhaseFileSubIdentifiers
        ) = createBuildPhases(
            consolidatedInputs: consolidatedInputs,
            hasCParams: aTargetArguments.hasCParams,
            hasCxxParams: aTargetArguments.hasCxxParams,
            hasLinkParams: topLevelTargetAttributes[id]?.linkParams != nil,
            identifier: identifier,
            productType: productType,
            shard: shard,
            usesInfoPlist: isBundle,
            watchKitExtensionProductIdentifier:
                entry.watchKitExtensionProductIdentifier
        )

        let (
            configurationList,
            configurationObjects
        ) = try await createXcodeConfigurations(
            conditionalFiles: conditionalFiles,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            identifier: identifier,
            isBundle: isBundle,
            label: entry.label,
            name: entry.name,
            platformVariants: platformVariants,
            productName: productName,
            productPath: productPath,
            productType: productType,
            uiTestHostName: entry.uiTestHostName,
            xcodeConfigurations: xcodeConfigurations
        )

        let product = createProductObject(
            productType: productType,
            productPath: productPath,
            subIdentifier: productSubIdentifier,
            isAssociatedWithTarget: setsProductReference
        )

        let target = createTargetObject(
            identifier: identifier,
            productType: productType,
            productName: productName,
            productSubIdentifier: productSubIdentifier,
            setsProductReference: setsProductReference,
            dependencySubIdentifiers: entry.dependencySubIdentifiers,
            buildConfigurationListIdentifier: configurationList.identifier,
            buildPhaseIdentifiers: buildPhases.map(\.identifier)
        )

        let buildFileSubIdentifiers =
            [productSubIdentifier] + buildPhaseFileSubIdentifiers
        let objects = buildPhases + buildFileObjects + configurationObjects +
            [product, target]

        return (buildFileSubIdentifiers, objects)
    }
}

private extension PBXProductType {
    var isBundle: Bool {
        switch self {
        case .application,
                .messagesApplication,
                .onDemandInstallCapableApplication,
                .watch2App,
                .watch2AppContainer,
                .appExtension,
                .intentsServiceExtension,
                .messagesExtension,
                .stickerPack,
                .tvExtension,
                .extensionKitExtension,
                .watch2Extension,
                .xcodeExtension,
                .resourceBundle,
                .bundle,
                .ocUnitTestBundle,
                .unitTestBundle,
                .uiTestBundle,
                .framework,
                .staticFramework,
                .driverExtension,
                .instrumentsPackage,
                .systemExtension,
                .xpcService:
            return true
        default:
            return false
        }
    }

    var setsProductReference: Bool {
        // We remove the association for non-launchable and non-bundle products
        // to allow the correct path to be shown in the project navigator
        switch self {
        case .application,
                .messagesApplication,
                .onDemandInstallCapableApplication,
                .watch2App,
                .watch2AppContainer,
                .appExtension,
                .intentsServiceExtension,
                .messagesExtension,
                .stickerPack,
                .tvExtension,
                .extensionKitExtension,
                .watch2Extension,
                .xcodeExtension,
                .resourceBundle,
                .bundle,
                .ocUnitTestBundle,
                .unitTestBundle,
                .uiTestBundle,
                .framework,
                .staticFramework,
                .driverExtension,
                .instrumentsPackage,
                .systemExtension,
                .commandLineTool,
                .xpcService:
            return true
        default:
            return false
        }
    }
}
