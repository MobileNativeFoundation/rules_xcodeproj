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
        logger: DefaultLogger()
    )

    let environment: Environment

    init(environment: Environment = Generator.defaultEnvironment) {
        self.environment = environment
    }

    /// Generates an Xcode project for a given `Project`.
    func generate(project: Project) throws {
        let _ = environment.createProject(project)

        var targets = project.targets
        let invalidMerges = try environment.processTargetMerges(
            &targets,
            project.potentialTargetMerges,
            project.requiredLinks
        )

        for invalidMerge in invalidMerges {
            for destination in invalidMerge.destinations {
                environment.logger.logWarning("""
Was unable to merge "\(targets[invalidMerge.source]!.label) \
(\(targets[invalidMerge.source]!.configuration))" into \
"\(targets[destination]!.label) \
(\(targets[destination]!.configuration))"
""")
            }
        }
    }
}

/// When a potential merge wasn't valid, then the ids of the targets involved
/// are returned in this `struct`.
struct InvalidMerge: Equatable {
    let source: TargetID
    let destinations: Set<TargetID>
}
