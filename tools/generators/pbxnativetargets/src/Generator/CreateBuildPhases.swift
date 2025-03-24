import PBXProj

extension Generator {
    struct CreateBuildPhases {
        private let createBazelIntegrationBuildPhaseObject:
            CreateBazelIntegrationBuildPhaseObject
        private let createBuildFileSubIdentifier: CreateBuildFileSubIdentifier
        private let createCreateCompileDependenciesBuildPhaseObject:
            CreateCreateCompileDependenciesBuildPhaseObject
        private let createCreateLinkDependenciesBuildPhaseObject:
            CreateCreateLinkDependenciesBuildPhaseObject
        private let createEmbedAppExtensionsBuildPhaseObject:
            CreateEmbedAppExtensionsBuildPhaseObject
        private let createProductBuildFileObject: CreateProductBuildFileObject
        private let createSourcesBuildPhaseObject: CreateSourcesBuildPhaseObject
        private let createLinkBinaryWithLibrariesBuildPhaseObject:
            CreateLinkBinaryWithLibrariesBuildPhaseObject
        private let createFrameworkObject: CreateFrameworkObject
        private let createFrameworkBuildFileObject: CreateFrameworkBuildFileObject

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createBazelIntegrationBuildPhaseObject:
                CreateBazelIntegrationBuildPhaseObject,
            createBuildFileSubIdentifier: CreateBuildFileSubIdentifier,
            createCreateCompileDependenciesBuildPhaseObject:
                CreateCreateCompileDependenciesBuildPhaseObject,
            createCreateLinkDependenciesBuildPhaseObject:
                CreateCreateLinkDependenciesBuildPhaseObject,
            createEmbedAppExtensionsBuildPhaseObject:
                CreateEmbedAppExtensionsBuildPhaseObject,
            createProductBuildFileObject: CreateProductBuildFileObject,
            createSourcesBuildPhaseObject: CreateSourcesBuildPhaseObject,
            createLinkBinaryWithLibrariesBuildPhaseObject:
                CreateLinkBinaryWithLibrariesBuildPhaseObject,
            createFrameworkObject: CreateFrameworkObject,
            createFrameworkBuildFileObject: CreateFrameworkBuildFileObject,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createBazelIntegrationBuildPhaseObject =
                createBazelIntegrationBuildPhaseObject
            self.createBuildFileSubIdentifier = createBuildFileSubIdentifier
            self.createCreateCompileDependenciesBuildPhaseObject =
                createCreateCompileDependenciesBuildPhaseObject
            self.createCreateLinkDependenciesBuildPhaseObject =
                createCreateLinkDependenciesBuildPhaseObject
            self.createEmbedAppExtensionsBuildPhaseObject =
                createEmbedAppExtensionsBuildPhaseObject
            self.createProductBuildFileObject = createProductBuildFileObject
            self.createSourcesBuildPhaseObject = createSourcesBuildPhaseObject
            self.createLinkBinaryWithLibrariesBuildPhaseObject = createLinkBinaryWithLibrariesBuildPhaseObject
            self.createFrameworkObject = createFrameworkObject
            self.createFrameworkBuildFileObject = createFrameworkBuildFileObject

            self.callable = callable
        }

        /// Creates the build phase `Object`s for a target.
        func callAsFunction(
            consolidatedInputs: Target.ConsolidatedInputs,
            hasCParams: Bool,
            hasCxxParams: Bool,
            hasLinkParams: Bool,
            identifier: Identifiers.Targets.Identifier,
            productType: PBXProductType,
            shard: UInt8,
            usesInfoPlist: Bool,
            watchKitExtensionProductIdentifier:
                Identifiers.BuildFiles.SubIdentifier?
        ) -> (
            buildPhases: [Object],
            buildFileObjects: [Object],
            buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier]
        ) {
            return callable(
                /*consolidatedInputs:*/ consolidatedInputs,
                /*hasCParams:*/ hasCParams,
                /*hasCxxParams:*/ hasCxxParams,
                /*hasLinkParams:*/ hasLinkParams,
                /*identifier:*/ identifier,
                /*productType:*/ productType,
                /*shard:*/ shard,
                /*usesInfoPlist:*/ usesInfoPlist,
                /*watchKitExtensionProductIdentifier:*/
                    watchKitExtensionProductIdentifier,
                /*createBazelIntegrationBuildPhaseObject:*/
                    createBazelIntegrationBuildPhaseObject,
                /*createBuildFileSubIdentifier:*/ createBuildFileSubIdentifier,
                /*createCreateCompileDependenciesBuildPhaseObject:*/
                    createCreateCompileDependenciesBuildPhaseObject,
                /*createCreateLinkDependenciesBuildPhaseObject:*/
                    createCreateLinkDependenciesBuildPhaseObject,
                /*createEmbedAppExtensionsBuildPhaseObject:*/
                    createEmbedAppExtensionsBuildPhaseObject,
                /*createProductBuildFileObject:*/ createProductBuildFileObject,
                /*createSourcesBuildPhaseObject:*/ createSourcesBuildPhaseObject,
                /*createLinkBinaryWithLibrariesBuildPhaseObject:*/ createLinkBinaryWithLibrariesBuildPhaseObject,
                /*createFrameworkObject:*/ createFrameworkObject,
                /*createFrameworkBuildFileObject:*/ createFrameworkBuildFileObject
            )
        }
    }
}

// MARK: - CreateBuildPhases.Callable

extension Generator.CreateBuildPhases {
    typealias Callable = (
        _ consolidatedInputs: Target.ConsolidatedInputs,
        _ hasCParams: Bool,
        _ hasCxxParams: Bool,
        _ hasLinkParams: Bool,
        _ identifier: Identifiers.Targets.Identifier,
        _ productType: PBXProductType,
        _ shard: UInt8,
        _ usesInfoPlist: Bool,
        _ watchKitExtensionProductIdentifier:
            Identifiers.BuildFiles.SubIdentifier?,
        _ createBazelIntegrationBuildPhaseObject:
            Generator.CreateBazelIntegrationBuildPhaseObject,
        _ createBuildFileSubIdentifier: Generator.CreateBuildFileSubIdentifier,
        _ createCreateCompileDependenciesBuildPhaseObject:
            Generator.CreateCreateCompileDependenciesBuildPhaseObject,
        _ createCreateLinkDependenciesBuildPhaseObject:
            Generator.CreateCreateLinkDependenciesBuildPhaseObject,
        _ createEmbedAppExtensionsBuildPhaseObject:
            Generator.CreateEmbedAppExtensionsBuildPhaseObject,
        _ createProductBuildFileObject: Generator.CreateProductBuildFileObject,
        _ createSourcesBuildPhaseObject: Generator.CreateSourcesBuildPhaseObject,
        _ createLinkBinaryWithLibrariesBuildPhaseObject:
            Generator.CreateLinkBinaryWithLibrariesBuildPhaseObject,
        _ createFrameworkObject: Generator.CreateFrameworkObject,
        _ createFrameworkBuildFileObject: Generator.CreateFrameworkBuildFileObject
    ) -> (
        buildPhases: [Object],
        buildFileObjects: [Object],
        buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier]
    )

    static func defaultCallable(
        consolidatedInputs: Target.ConsolidatedInputs,
        hasCParams: Bool,
        hasCxxParams: Bool,
        hasLinkParams: Bool,
        identifier: Identifiers.Targets.Identifier,
        productType: PBXProductType,
        shard: UInt8,
        usesInfoPlist: Bool,
        watchKitExtensionProductIdentifier:
            Identifiers.BuildFiles.SubIdentifier?,
        createBazelIntegrationBuildPhaseObject:
            Generator.CreateBazelIntegrationBuildPhaseObject,
        createBuildFileSubIdentifier: Generator.CreateBuildFileSubIdentifier,
        createCreateCompileDependenciesBuildPhaseObject:
            Generator.CreateCreateCompileDependenciesBuildPhaseObject,
        createCreateLinkDependenciesBuildPhaseObject:
            Generator.CreateCreateLinkDependenciesBuildPhaseObject,
        createEmbedAppExtensionsBuildPhaseObject:
            Generator.CreateEmbedAppExtensionsBuildPhaseObject,
        createProductBuildFileObject: Generator.CreateProductBuildFileObject,
        createSourcesBuildPhaseObject: Generator.CreateSourcesBuildPhaseObject,
        createLinkBinaryWithLibrariesBuildPhaseObject:
            Generator.CreateLinkBinaryWithLibrariesBuildPhaseObject,
        createFrameworkObject: Generator.CreateFrameworkObject,
        createFrameworkBuildFileObject: Generator.CreateFrameworkBuildFileObject
    ) -> (
        buildPhases: [Object],
        buildFileObjects: [Object],
        buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier]
    ) {
        var buildPhases: [Object] = []
        var buildFileObjects: [Object] = []
        var buildFileSubIdentifiers: [Identifiers.BuildFiles.SubIdentifier] = []

        if let watchKitExtensionProductIdentifier {
            // FIXME: Make a version that just takes `watchKitExtensionProductIdentifier`?
            let watchKitExtensionBuildFileSubIdentifier =
                createBuildFileSubIdentifier(
                    watchKitExtensionProductIdentifier.path,
                    type: .watchKitExtension,
                    shard: shard
                )

            let watchKitExtensionBuildFileObject = createProductBuildFileObject(
                productSubIdentifier: watchKitExtensionProductIdentifier,
                subIdentifier: watchKitExtensionBuildFileSubIdentifier
            )
            buildFileObjects.append(watchKitExtensionBuildFileObject)

            buildPhases.append(
                createEmbedAppExtensionsBuildPhaseObject(
                    subIdentifier: identifier.subIdentifier,
                    buildFileIdentifiers: [
                        watchKitExtensionBuildFileObject.identifier,
                    ]
                )
            )
        }

        if let buildPhase = createBazelIntegrationBuildPhaseObject(
            subIdentifier: identifier.subIdentifier,
            productType: productType,
            usesInfoPlist: usesInfoPlist
        ) {
            buildPhases.append(buildPhase)
        }

        if let buildPhase = createCreateCompileDependenciesBuildPhaseObject(
            subIdentifier: identifier.subIdentifier,
            hasCParams: hasCParams,
            hasCxxParams: hasCxxParams
        ) {
            buildPhases.append(buildPhase)
        }

        let hasCompilePhase = productType.hasCompilePhase
        let hasCompileStub = hasCompilePhase &&
            consolidatedInputs.srcs.isEmpty &&
            consolidatedInputs.nonArcSrcs.isEmpty

        if hasLinkParams {
            buildPhases.append(
                createCreateLinkDependenciesBuildPhaseObject(
                    subIdentifier: identifier.subIdentifier,
                    hasCompileStub: hasCompileStub
                )
            )
        }

        if hasCompilePhase {
            // FIXME: Extract this scope into a function -> BuildPhase

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
                let srcsSubIdentifiers = consolidatedInputs.srcs.map { path in
                    return createBuildFileSubIdentifier(
                        path,
                        type: .source,
                        shard: shard
                    )
                }
                buildFileSubIdentifiers.append(contentsOf: srcsSubIdentifiers)

                let nonArcSrcsSubIdentifiers =
                    consolidatedInputs.nonArcSrcs.map { path in
                        return createBuildFileSubIdentifier(
                            path,
                            type: .nonArcSource,
                            shard: shard
                        )
                    }
                buildFileSubIdentifiers
                    .append(contentsOf: nonArcSrcsSubIdentifiers)

                sourcesIdentifiers = (srcsSubIdentifiers +
                                      nonArcSrcsSubIdentifiers)
                    .map { Identifiers.BuildFiles.id(subIdentifier: $0) }
            }

            buildPhases.append(
                createSourcesBuildPhaseObject(
                    subIdentifier: identifier.subIdentifier,
                    buildFileIdentifiers: sourcesIdentifiers
                )
            )
        }

        let librariesToLinkSubIdentifiers = consolidatedInputs.librariesToLinkPaths.map { bazelPath in
            return (
                bazelPath,
                createBuildFileSubIdentifier(
                    BazelPath(bazelPath.path.split(separator: "/").last.map(String.init)!),
                    type: .framework,
                    shard: shard
                ),
                createBuildFileSubIdentifier(
                    bazelPath,
                    type: .framework,
                    shard: shard
                )
            )
        }
        librariesToLinkSubIdentifiers
            .forEach { bazelPath, buildSubIdentifier, frameworkSubIdentifier  in
                buildFileObjects.append(
                    createFrameworkBuildFileObject(
                        frameworkSubIdentifier: frameworkSubIdentifier,
                        subIdentifier: buildSubIdentifier
                    )
                )
                buildFileObjects.append(
                    createFrameworkObject(
                        frameworkPath: bazelPath,
                        subIdentifier: frameworkSubIdentifier
                    )
                )
            }
        buildPhases.append(
            createLinkBinaryWithLibrariesBuildPhaseObject(
                subIdentifier: identifier.subIdentifier,
                librariesToLinkIdentifiers: librariesToLinkSubIdentifiers
                    .map { $0.1 }
                    .map { Identifiers.BuildFiles.id(subIdentifier: $0) }
            )
        )

        return (buildPhases, buildFileObjects, buildFileSubIdentifiers)
    }
}

private extension PBXProductType {
    var hasCompilePhase: Bool {
        switch self {
        case .application,
             .onDemandInstallCapableApplication,
             .appExtension,
             .intentsServiceExtension,
             .messagesExtension,
             .stickerPack,
             .tvExtension,
             .extensionKitExtension,
             .watch2Extension,
             .xcodeExtension,
             .bundle,
             .ocUnitTestBundle,
             .unitTestBundle,
             .uiTestBundle,
             .framework,
             .staticFramework,
             .xcFramework,
             .dynamicLibrary,
             .staticLibrary,
             .driverExtension,
             .instrumentsPackage,
             .metalLibrary,
             .systemExtension,
             .commandLineTool,
             .xpcService:
            return true
        case .messagesApplication,
             .watch2App,
             .watch2AppContainer,
             .resourceBundle:
            return false
        }
    }
}
