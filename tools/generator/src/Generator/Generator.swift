import PathKit
import XcodeProj

/// A class that generates and writes to disk an Xcode project.
///
/// The `Generator` class is stateless. It can be used to generate multiple
/// projects. The `generate()` method is passed all the inputs needed to
/// generate a project.
class Generator {
    static let defaultEnvironment = Environment(
        createProject: Generator.createProject,
        processReplacementLabels: Generator.processReplacementLabels,
        processTargetMerges: Generator.processTargetMerges,
        consolidateTargets: Generator.consolidateTargets,
        createFilesAndGroups: Generator.createFilesAndGroups,
        createProducts: Generator.createProducts,
        populateMainGroup: populateMainGroup,
        disambiguateTargets: Generator.disambiguateTargets,
        addBazelDependenciesTarget: Generator.addBazelDependenciesTarget,
        addTargets: Generator.addTargets,
        setTargetConfigurations: Generator.setTargetConfigurations,
        setTargetDependencies: Generator.setTargetDependencies,
        createCustomXCSchemes: Generator.createCustomXCSchemes,
        createAutogeneratedXCSchemes: Generator.createAutogeneratedXCSchemes,
        createXCSharedData: Generator.createXCSharedData,
        createXcodeProj: Generator.createXcodeProj,
        writeXcodeProj: Generator.writeXcodeProj
    )

    let environment: Environment
    let logger: Logger

    init(
        environment: Environment = Generator.defaultEnvironment,
        logger: Logger
    ) {
        self.logger = logger
        self.environment = environment
    }

    /// Generates an Xcode project for a given `Project`.
    func generate(
        buildMode: BuildMode,
        project: Project,
        xccurrentversions: [XCCurrentVersion],
        extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        workspaceDirectory: Path,
        projectRootDirectory: Path,
        externalDirectory: Path,
        bazelOutDirectory: Path,
        internalDirectoryName: String,
        bazelIntegrationDirectory: Path,
        workspaceOutputPath: Path,
        outputPath: Path
    ) throws {
        let filePathResolver = FilePathResolver(
            workspaceDirectory: workspaceDirectory,
            externalDirectory: externalDirectory,
            bazelOutDirectory: bazelOutDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let pbxProj = environment.createProject(
            buildMode,
            project,
            projectRootDirectory,
            filePathResolver
        )
        guard let pbxProject = pbxProj.rootObject else {
            throw PreconditionError(message: """
`rootObject` not set on `pbxProj`
""")
        }
        let mainGroup: PBXGroup = pbxProject.mainGroup

        var targets = project.targets
        try environment.processReplacementLabels(
            &targets,
            project.replacementLabels
        )
        try environment.processTargetMerges(&targets, project.targetMerges)

        let isUnfocusedDependencyTargetIDs = Set(
            targets.filter(\.value.isUnfocusedDependency).keys
        )
        for id in targets.keys {
            targets[id]!.dependencies.subtract(isUnfocusedDependencyTargetIDs)
        }

        let consolidatedTargets = try environment.consolidateTargets(
            targets,
            logger
        )

        let (
            files,
            rootElements,
            xcodeGeneratedFiles,
            resolvedExternalRepositories
        ) = try environment.createFilesAndGroups(
            pbxProj,
            buildMode,
            project.forceBazelDependencies,
            targets,
            project.extraFiles,
            xccurrentversions,
            filePathResolver,
            logger
        )
        let (products, productsGroup) = environment.createProducts(
            pbxProj,
            consolidatedTargets
        )
        environment.populateMainGroup(
            mainGroup,
            pbxProj,
            rootElements,
            productsGroup
        )

        let disambiguatedTargets = environment.disambiguateTargets(
            consolidatedTargets
        )
        let bazelDependencies = try environment.addBazelDependenciesTarget(
            pbxProj,
            buildMode,
            project.forceBazelDependencies,
            project.indexImport,
            files,
            filePathResolver,
            resolvedExternalRepositories,
            project.bazelConfig,
            project.label,
            project.configuration,
            consolidatedTargets
        )
        let pbxTargets = try environment.addTargets(
            pbxProj,
            disambiguatedTargets,
            buildMode,
            products,
            files,
            filePathResolver,
            bazelDependencies
        )
        try environment.setTargetConfigurations(
            pbxProj,
            disambiguatedTargets,
            buildMode,
            pbxTargets,
            project.targetHosts,
            bazelDependencies != nil,
            xcodeGeneratedFiles,
            filePathResolver
        )
        try environment.setTargetDependencies(
            disambiguatedTargets,
            pbxTargets
        )

        let targetResolver = try TargetResolver(
            referencedContainer: filePathResolver.containerReference,
            targets: targets,
            targetHosts: project.targetHosts,
            extensionPointIdentifiers: extensionPointIdentifiers,
            consolidatedTargetKeys: disambiguatedTargets.keys,
            pbxTargets: pbxTargets
        )
        var schemes = try environment.createCustomXCSchemes(
            project.customXcodeSchemes,
            buildMode,
            targetResolver,
            project.label
        )
        let customSchemeNames = Set(schemes.map(\.name))
        schemes.append(contentsOf: try environment.createAutogeneratedXCSchemes(
            project.schemeAutogenerationMode,
            buildMode,
            targetResolver,
            customSchemeNames
        ))
        let sharedData = environment.createXCSharedData(schemes)

        let xcodeProj = environment.createXcodeProj(pbxProj, sharedData)
        try environment.writeXcodeProj(
            xcodeProj,
            files,
            internalDirectoryName,
            bazelIntegrationDirectory,
            outputPath
        )
    }
}
