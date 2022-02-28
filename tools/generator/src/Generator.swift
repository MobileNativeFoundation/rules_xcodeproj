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
        addTargets: Generator.addTargets,
        setTargetConfigurations: Generator.setTargetConfigurations
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
        project: Project,
        projectRootDirectory: Path,
        externalDirectory: Path,
        internalDirectoryName: String,
        workspaceOutputPath: Path
    ) throws {
        let pbxProj = environment.createProject(project, projectRootDirectory)
        guard let pbxProject = pbxProj.rootObject else {
            throw PreconditionError(message: """
`rootObject` not set on `pbxProj`
""")
        }
        let mainGroup: PBXGroup = pbxProject.mainGroup

        var targets = project.targets
        let invalidMerges = try environment.processTargetMerges(
            &targets,
            project.potentialTargetMerges,
            project.requiredLinks
        )

        for invalidMerge in invalidMerges {
            for destination in invalidMerge.destinations {
                logger.logWarning("""
Was unable to merge "\(targets[invalidMerge.source]!.label) \
(\(targets[invalidMerge.source]!.configuration))" into \
"\(targets[destination]!.label) \
(\(targets[destination]!.configuration))"
""")
            }
        }

        let (files, rootElements) = environment.createFilesAndGroups(
            pbxProj,
            targets,
            project.extraFiles,
            externalDirectory,
            internalDirectoryName,
            workspaceOutputPath
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
        let pbxTargets = try environment.addTargets(
            pbxProj,
            disambiguatedTargets,
            products,
            files
        )
        try environment.setTargetConfigurations(
            pbxProj,
            disambiguatedTargets,
            pbxTargets
        )
    }
}

/// When a potential merge wasn't valid, then the ids of the targets involved
/// are returned in this `struct`.
struct InvalidMerge: Equatable {
    let source: TargetID
    let destinations: Set<TargetID>
}
