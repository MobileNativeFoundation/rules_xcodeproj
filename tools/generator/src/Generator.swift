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
        processTargetMerges: Generator.processTargetMerges,
        createFilesAndGroups: Generator.createFilesAndGroups,
        createProducts: Generator.createProducts,
        populateMainGroup: populateMainGroup,
        disambiguateTargets: Generator.disambiguateTargets,
        addBazelDependenciesTarget: Generator.addBazelDependenciesTarget,
        addTargets: Generator.addTargets,
        setTargetConfigurations: Generator.setTargetConfigurations,
        setTargetDependencies: Generator.setTargetDependencies,
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
        projectRootDirectory: Path,
        internalDirectoryName: String,
        workspaceOutputPath: Path,
        outputPath: Path
    ) throws {
        let filePathResolver = FilePathResolver(
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
        try environment.processTargetMerges(&targets, project.targetMerges)

        for (src, destinations) in project.invalidTargetMerges {
            guard let srcTarget = targets[src] else {
                throw PreconditionError(
                    message: """
Source target "\(src)" not found in `targets`
""")
            }
            for destination in destinations {
                guard let destTarget = targets[destination] else {
                    throw PreconditionError(message: """
Destination target "\(destination)" not found in `targets`
""")
                }
                logger.logWarning("""
Was unable to merge "\(srcTarget.label) \
(\(srcTarget.configuration))" into \
"\(destTarget.label) \
(\(destTarget.configuration))"
""")
            }
        }

        let (files, rootElements) = try environment.createFilesAndGroups(
            pbxProj,
            targets,
            project.extraFiles,
            filePathResolver
        )
        let (products, productsGroup) = environment.createProducts(
            pbxProj,
            targets
        )
        environment.populateMainGroup(
            mainGroup,
            pbxProj,
            rootElements,
            productsGroup
        )

        let disambiguatedTargets = environment.disambiguateTargets(targets)
        let bazelDependencies = try environment.addBazelDependenciesTarget(
            pbxProj,
            buildMode,
            files,
            filePathResolver,
            project.label
        )
        let pbxTargets = try environment.addTargets(
            pbxProj,
            disambiguatedTargets,
            products,
            files,
            filePathResolver,
            bazelDependencies
        )
        try environment.setTargetConfigurations(
            pbxProj,
            disambiguatedTargets,
            pbxTargets,
            filePathResolver
        )
        try environment.setTargetDependencies(
            disambiguatedTargets,
            pbxTargets
        )

         let xcodeProj = environment.createXcodeProj(pbxProj)
         try environment.writeXcodeProj(
            xcodeProj,
            files,
            internalDirectoryName,
            outputPath
         )
    }
}

/// When a potential merge wasn't valid, then the ids of the targets involved
/// are returned in this `struct`.
struct InvalidMerge: Equatable {
    let source: TargetID
    let destinations: Set<TargetID>
}
