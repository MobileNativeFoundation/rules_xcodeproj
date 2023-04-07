import CustomDump
import XCTest

@testable import generator

final class SetTargetDependenciesTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let directories = Directories(
            workspace: "/Users/TimApple/app",
            projectRoot: "/Users/TimApple",
            executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
            internalDirectoryName: "rules_xcodeproj",
            workspaceOutput: "out/p.xcodeproj"
        )

        let consolidatedTargets = Fixtures.consolidatedTargets

        let bazelDependenciesTarget = Fixtures.bazelDependenciesTarget(
            in: pbxProj
        )
        let expectedBazelDependenciesTarget = Fixtures.bazelDependenciesTarget(
            in: expectedPBXProj
        )

        let (pbxTargets, disambiguatedTargets) = Fixtures.pbxTargets(
            in: pbxProj,
            directories: directories,
            consolidatedTargets: consolidatedTargets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithDependencies(
            in: expectedPBXProj,
            directories: directories,
            consolidatedTargets: consolidatedTargets,
            bazelDependenciesTarget: expectedBazelDependenciesTarget
        )

        // Act

        try Generator.setTargetDependencies(
            buildMode: .xcode,
            disambiguatedTargets: disambiguatedTargets,
            pbxTargets: pbxTargets,
            bazelDependenciesTarget: bazelDependenciesTarget
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
