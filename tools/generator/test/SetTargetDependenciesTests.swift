import CustomDump
import XCTest

@testable import generator

final class SetTargetDependenciesTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let directories = FilePathResolver.Directories(
            workspace: "/Users/TimApple/app",
            projectRoot: "/Users/TimApple",
            external: "/some/bazel81/external",
            bazelOut: "/some/bazel81/bazel-out",
            internalDirectoryName: "rules_xcodeproj",
            bazelIntegration: "stubs",
            workspaceOutput: "out/p.xcodeproj"
        )

        let consolidatedTargets = Fixtures.consolidatedTargets

        let (pbxTargets, disambiguatedTargets, _, _) = Fixtures.pbxTargets(
            in: pbxProj,
            directories: directories,
            consolidatedTargets: consolidatedTargets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithDependencies(
            in: expectedPBXProj,
            directories: directories,
            consolidatedTargets: consolidatedTargets
        )

        // Act

        try Generator.setTargetDependencies(
            buildMode: .xcode,
            disambiguatedTargets: disambiguatedTargets,
            pbxTargets: pbxTargets
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
