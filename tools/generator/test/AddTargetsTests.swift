import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class AddTargetsTests: XCTestCase {
    func test_integration() async throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let consolidatedTargets = Fixtures.consolidatedTargets
        let workspaceDirectory: Path = "/app-project"
        let projectRootDirectory: Path = "~/Developer/project"
        let executionRootDirectory: Path = "/some/bazel11"
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let directories = Directories(
            workspace: workspaceDirectory,
            projectRoot: projectRootDirectory,
            executionRoot: executionRootDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutput: workspaceOutputPath
        )

        let (files, _, _, compileStub, _, _) = Fixtures.files(
            in: pbxProj,
            buildMode: .xcode,
            directories: directories,
            parentGroup: mainGroup
        )
        let (expectedFiles, _, _, expectedCompileStub, _, _) = Fixtures.files(
            in: expectedPBXProj,
            buildMode: .xcode,
            directories: directories,
            parentGroup: expectedMainGroup
        )

        let products = Fixtures.products(in: pbxProj, parentGroup: mainGroup)
        let expectedProducts = Fixtures.products(
            in: expectedPBXProj,
            parentGroup: expectedMainGroup
        )

        let disambiguatedTargets = Fixtures.disambiguatedTargets(
            consolidatedTargets
        )
        let expectedTargets = Fixtures.pbxTargets(
            in: expectedPBXProj,
            disambiguatedTargets: disambiguatedTargets,
            files: expectedFiles,
            compileStub: expectedCompileStub,
            products: expectedProducts
        )

        // Act

        let createdTargets = try await Generator.addTargets(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            products: products,
            files: files,
            compileStub: compileStub
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(
            createdTargets.map(KeyAndValue.init).sorted(),
            expectedTargets.map(KeyAndValue.init).sorted()
        )

        // We only need the rest of the asserts if the targets are equivalent
        guard createdTargets == expectedTargets else { return }

        for (key, target) in expectedTargets {
            guard let createdTarget = createdTargets[key] else { continue }
            // The assert above won't tell us when the build phases are
            // different, and the assert below won't give us the context of
            // which target, so we assert here as well.
            XCTAssertNoDifference(
                createdTarget.buildPhases,
                target.buildPhases,
                "\(key)"
            )
        }

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
