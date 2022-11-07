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
            external: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/external",
            bazelOut: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/com_github_buildbuddy_io_rules_xcodeproj/bazel-out",
            internalDirectoryName: "rules_xcodeproj",
            workspaceOutput: "out/p.xcodeproj"
        )

        let consolidatedTargets = Fixtures.consolidatedTargets

        let (pbxTargets, disambiguatedTargets, _) = Fixtures.pbxTargets(
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
