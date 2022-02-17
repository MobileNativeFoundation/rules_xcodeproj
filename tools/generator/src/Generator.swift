import XcodeProj

class Generator {
    static let defaultEnvironment = Environment(
        createProject: Generator.createProject
    )

    static func createProject(project: Project) -> (PBXProj, PBXProject) {
        let pbxProj = PBXProj()

        let mainGroup = PBXGroup()
        pbxProj.add(object: mainGroup)

        let buildConfigurationList = XCConfigurationList()
        pbxProj.add(object: buildConfigurationList)

        let attributes = [
            "BuildIndependentTargetsInParallel": 1,
            // TODO: Generate these. Hardcoded to Xcode 13.2.0 for now.
            "LastSwiftUpdateCheck": 1320,
            "LastUpgradeCheck": 1320,
        ]

        let pbxProject = PBXProject(
            name: project.name,
            buildConfigurationList: buildConfigurationList,
            // TODO: Calculate `compatibilityVersion`
            compatibilityVersion: "Xcode 13.0",
            mainGroup: mainGroup,
            // TODO: Make regions configurable?
            developmentRegion: "en",
            knownRegions: ["en", "Base"],
            attributes: attributes
        )
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        return (pbxProj, pbxProject)
    }

    // MARK: API

    let environment: Environment

    init(environment: Environment = Generator.defaultEnvironment) {
        self.environment = environment
    }

    func generate(project: Project) throws {
        let _ = environment.createProject(project)
    }
}
