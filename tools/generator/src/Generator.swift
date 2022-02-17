import XcodeProj

class Generator {
    static let defaultEnvironment = Environment(
        createProject: Generator.createProject
    )

    let environment: Environment

    init(environment: Environment = Generator.defaultEnvironment) {
        self.environment = environment
    }

    func generate(project: Project) throws {
        let _ = environment.createProject(project)
    }
}
