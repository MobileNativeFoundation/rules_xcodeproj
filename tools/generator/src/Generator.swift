import XcodeProj

/// A class that generates and writes to disk an Xcode project.
///
/// The `Generator` class is stateless. It can be used to generate multiple
/// projects. The `generate()` method is passed all the inputs needed to
/// generate a project.
class Generator {
    static let defaultEnvironment = Environment(
        createProject: Generator.createProject
    )

    let environment: Environment

    init(environment: Environment = Generator.defaultEnvironment) {
        self.environment = environment
    }

    /// Generates an Xcode project for a given `Project`.
    func generate(project: Project) throws {
        let _ = environment.createProject(project)
    }
}
