import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class CreateFilesAndGroupsTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let targets = Fixtures.targets
        let extraFiles = Fixtures.project.extraFiles
        let externalDirectory = Path("/ext")
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath = Path("Project.xcodeproj")

        let expectedFilesAndGroups = Fixtures.files(
            in: expectedPBXProj,
            externalDirectory: externalDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let expectedRootElements: [PBXFileElement] = [
            // Root group that holds "a/b/c.m" and "a/a.h"
            expectedFilesAndGroups["a"]!,
            // Root group that holds "x/y.swift"
            expectedFilesAndGroups["x"]!,
            // Files are sorted below groups
            expectedFilesAndGroups["Assets.xcassets"]!,
            expectedFilesAndGroups["b.c"]!,
            expectedFilesAndGroups["z.mm"]!,
            // Then Bazel External Repositories
            expectedFilesAndGroups["external"]!,
            // And finally the internal (rules_xcodeproj) group
            expectedFilesAndGroups[.internal("")]!,
        ]
        expectedMainGroup.addChildren(expectedRootElements)

        // Act

        let (
            createdFilesAndGroups,
            createdRootElements
        ) = Generator.createFilesAndGroups(
            in: pbxProj,
            targets: targets,
            extraFiles: extraFiles,
            externalDirectory: externalDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        // We need to add the `rootElements` to a group to allow references to
        // become fixed
        mainGroup.addChildren(createdRootElements)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdRootElements, expectedRootElements)
        XCTAssertNoDifference(createdFilesAndGroups, expectedFilesAndGroups)

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
