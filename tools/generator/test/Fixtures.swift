import XcodeProj

@testable import generator

enum Fixtures {
    static let project = Project(
        name: "Bazel",
        targets: targets,
        potentialTargetMerges: [:],
        requiredLinks: []
    )

    static let targets: [TargetID: Target] = [
        "A 1": Target.mock(
            product: .init(type: .staticLibrary, name: "a", path: "z/A.a"),
            buildSettings: [
                "PRODUCT_MODULE_NAME": .string("A"),
                "T": .string("42"),
                "Y": .bool(true),
            ],
            srcs: ["x/y.swift", "b.c"]
        ),
        "A 2": Target.mock(
            product: .init(type: .application, name: "A", path: "z/A.app"),
            buildSettings: [
                "PRODUCT_MODULE_NAME": .string("_Stubbed_A"),
                "T": .string("43"),
                "Z": .string("0")
            ],
            links: ["a/c.a", "z/A.a"],
            dependencies: ["C 1", "A 1"]
        ),
        "B 1": Target.mock(
            product: .init(type: .staticLibrary, name: "b", path: "a/b.a"),
            srcs: ["z.mm"],
            dependencies: ["A 1"]
        ),
        // "B 2" not having a link on "A 1" represents a bundle_loader like
        // relationship. This allows "A 1" to merge into "A 2".
        "B 2": Target.mock(
            product: .init(type: .unitTestBundle, name: "B", path: "B.xctest"),
            links: ["a/b.a"],
            dependencies: ["B 1"]
        ),
        "C 1": Target.mock(
            product: .init(type: .staticLibrary, name: "c", path: "a/c.a"),
            srcs: ["a/b/c.m"]
        ),
        "E1": Target.mock(
            product: .init(type: .staticLibrary, name: "E1", path: "e1/E.a"),
            srcs: ["external/a_repo/a.swift"]
        ),
        "E2": Target.mock(
            product: .init(type: .staticLibrary, name: "E2", path: "e2/E.a"),
            srcs: ["external/another_repo/b.swift"]
        ),
    ]
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
