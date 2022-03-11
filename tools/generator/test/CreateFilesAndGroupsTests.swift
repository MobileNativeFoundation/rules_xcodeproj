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

        let targets: [TargetID: Target] = [
            "A": Target.mock(
                product: .init(type: .staticLibrary, name: "a", path: "liba.a"),
                srcs: ["a.swift"]
            ),
        ]
        let extraFiles: Set<FilePath> = []
        let externalDirectory = Path("/ext")
        let generatedDirectory = Path("/bazel-leave")
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath = Path("Project.xcodeproj")

        let expectedFiles: [FilePath: File] = [
            "a.swift": File(reference: PBXFileReference(
                sourceTree: .group,
                lastKnownFileType: "sourcecode.swift",
                path: "a.swift"
            )),
        ]
        expectedPBXProj.add(object: expectedFiles["a.swift"]!.reference)

        let expectedRootElements: [PBXFileElement] = [
            expectedFiles["a.swift"]!.reference,
        ]
        expectedMainGroup.addChildren(expectedRootElements)

        // Act

        let (
            createdFiles,
            createdRootElements
        ) = Generator.createFilesAndGroups(
            in: pbxProj,
            targets: targets,
            extraFiles: extraFiles,
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory,
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
        XCTAssertNoDifference(createdFiles, expectedFiles)

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }

    func test_full() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let targets = Fixtures.targets
        let extraFiles = Fixtures.project.extraFiles
        let externalDirectory = Path("/ext")
        let generatedDirectory = Path("/bazel-leave")
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath = Path("Project.xcodeproj")

        let (expectedFiles, expectedElements) = Fixtures.files(
            in: expectedPBXProj,
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let expectedRootElements: [PBXFileElement] = [
            // Root group that holds "a/b/c.m" and "a/a.h"
            expectedElements["a"]!,
            // Root group that holds "x/y.swift"
            expectedElements["x"]!,
            // Files are sorted below groups
            expectedElements["Assets.xcassets"]!,
            expectedElements["b.c"]!,
            expectedElements["z.mm"]!,
            // Then Bazel External Repositories
            expectedElements[.external("")]!,
            // Then Bazel Generated Files
            expectedElements[.generated("")]!,
            // And finally the internal (rules_xcodeproj) group
            expectedElements[.internal("")]!,
        ]
        expectedMainGroup.addChildren(expectedRootElements)

        // Act

        let (
            createdFiles,
            createdRootElements
        ) = Generator.createFilesAndGroups(
            in: pbxProj,
            targets: targets,
            extraFiles: extraFiles,
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory,
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
        XCTAssertNoDifference(createdFiles, expectedFiles)

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
