import XcodeProj

@testable import generator

enum Fixtures {
    static let project = Project(
        name: "Bazel"
    )

    static func pbxProject() -> (PBXProj, PBXProject) {
        let pbxProj = PBXProj()

        let mainGroup = PBXGroup()
        pbxProj.add(object: mainGroup)

        let buildConfigurationList = XCConfigurationList()
        pbxProj.add(object: buildConfigurationList)

        let pbxProject = PBXProject(
            name: "Project",
            buildConfigurationList: buildConfigurationList,
            compatibilityVersion: "Xcode 13.0",
            mainGroup: mainGroup
        )
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        return (pbxProj, pbxProject)
    }
}
