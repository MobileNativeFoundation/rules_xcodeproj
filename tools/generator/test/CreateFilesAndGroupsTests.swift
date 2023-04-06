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
                inputs: .init(srcs: ["a.swift"])
            ),
        ]
        let extraFiles: Set<FilePath> = []
        let xccurrentversions: [XCCurrentVersion] = []
        let workspaceDirectory: Path = "/app-project"
        let projectRootDirectory: Path = "/"
        let executionRootDirectory: Path = "/some/bazel12"
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let directories = Directories(
            workspace: workspaceDirectory,
            projectRoot: projectRootDirectory,
            executionRoot: executionRootDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutput: workspaceOutputPath
        )

        let expectedFiles: [FilePath: File] = [
            "a.swift": .reference(PBXFileReference(
                sourceTree: .group,
                lastKnownFileType: "sourcecode.swift",
                path: "a.swift"
            )),
        ]
        expectedPBXProj.add(object: expectedFiles["a.swift"]!.fileElement!)

        let expectedRootElements: [PBXFileElement] = [
            expectedFiles["a.swift"]!.fileElement!,
        ]
        expectedMainGroup.addChildren(expectedRootElements)

        expectedPBXProj.rootObject!.knownRegions = ["en", "Base"]

        // Act

        let (
            createdFiles,
            createdRootElements,
            _,
            _,
            _,
            _,
            _
        ) = try Generator.createFilesAndGroups(
            in: pbxProj,
            buildMode: .xcode,
            forFixtures: false,
            targets: targets,
            extraFiles: extraFiles,
            xccurrentversions: xccurrentversions,
            directories: directories,
            logger: StubLogger()
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

    func test_integration_xcode() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let targets = Fixtures.targets
        let extraFiles = Fixtures.project.extraFiles
        let xccurrentversions = Fixtures.xccurrentversions
        let workspaceDirectory: Path = "/Users/TimApple/app"
        let projectRootDirectory: Path = "/Users/TimApple"
        let executionRootDirectory: Path = "/some/bazel15"
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let directories = Directories(
            workspace: workspaceDirectory,
            projectRoot: projectRootDirectory,
            executionRoot: executionRootDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutput: workspaceOutputPath
        )

        let (
            expectedFiles,
            expectedElements,
            expectedInternalGroup,
            _,
            _,
            expectedInternalFiles
        ) = Fixtures.files(
            in: expectedPBXProj,
            buildMode: .xcode,
            directories: directories
        )

        let expectedRootElements: [PBXFileElement] = [
            // Root group that holds "a/b/c.m" and "a/a.h"
            expectedElements["a"]!,
            // Root group that holds "r1/X.txt" and others
            expectedElements["r1"]!,
            expectedElements["T"]!,
            // Root group that holds "x/y.swift"
            expectedElements["x"]!,
            // Files are sorted below groups
            expectedElements["app.entitlements"]!,
            expectedElements["Assets.xcassets"]!,
            expectedElements["b.c"]!,
            expectedElements["d.h"]!,
            expectedElements["Example.xib"]!,
            expectedElements["Localized.strings"]!,
            expectedElements["z.h"]!,
            expectedElements["z.mm"]!,
            // Then Bazel External Repositories
            expectedElements[.external("")]!,
            // Then Bazel Generated Files
            expectedElements[.generated("")]!,
            // And finally the internal (rules_xcodeproj) group
            expectedInternalGroup,
        ]
        expectedMainGroup.addChildren(expectedRootElements)

        expectedPBXProj.rootObject!.knownRegions = ["en", "es", "Base"]

        // Act

        let (
            createdFiles,
            createdRootElements,
            _,
            _,
            internalFiles,
            _,
            _
        ) = try Generator.createFilesAndGroups(
            in: pbxProj,
            buildMode: .xcode,
            forFixtures: false,
            targets: targets,
            extraFiles: extraFiles,
            xccurrentversions: xccurrentversions,
            directories: directories,
            logger: StubLogger()
        )

        // We need to add the `rootElements` to a group to allow references to
        // become fixed
        mainGroup.addChildren(createdRootElements)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdRootElements, expectedRootElements)
        XCTAssertNoDifference(
            createdFiles.map(KeyAndValue.init).sorted(),
            expectedFiles.map(KeyAndValue.init).sorted()
        )
        XCTAssertNoDifference(
            internalFiles.map(KeyAndValue.init).sorted(),
            expectedInternalFiles.map(KeyAndValue.init).sorted()
        )

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }

    func test_integration_bazel() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let targets = Fixtures.targets
        let extraFiles = Fixtures.project.extraFiles
        let xccurrentversions = Fixtures.xccurrentversions
        let workspaceDirectory: Path = "/Users/TimApple/app"
        let projectRootDirectory: Path = "/Users/TimApple"
        let executionRootDirectory: Path = "/some/bazel15"
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let directories = Directories(
            workspace: workspaceDirectory,
            projectRoot: projectRootDirectory,
            executionRoot: executionRootDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutput: workspaceOutputPath
        )

        let (
            expectedFiles,
            expectedElements,
            expectedInternalGroup,
            _,
            _,
            expectedInternalFiles
        ) = Fixtures.files(
            in: expectedPBXProj,
            buildMode: .bazel,
            directories: directories
        )

        let expectedRootElements: [PBXFileElement] = [
            // Root group that holds "a/b/c.m" and "a/a.h"
            expectedElements["a"]!,
            // Root group that holds "r1/X.txt" and others
            expectedElements["r1"]!,
            expectedElements["T"]!,
            // Root group that holds "x/y.swift"
            expectedElements["x"]!,
            // Files are sorted below groups
            expectedElements["app.entitlements"]!,
            expectedElements["Assets.xcassets"]!,
            expectedElements["b.c"]!,
            expectedElements["d.h"]!,
            expectedElements["Example.xib"]!,
            expectedElements["Localized.strings"]!,
            expectedElements["z.h"]!,
            expectedElements["z.mm"]!,
            // Then Bazel External Repositories
            expectedElements[.external("")]!,
            // Then Bazel Generated Files
            expectedElements[.generated("")]!,
            // And finally the internal (rules_xcodeproj) group
            expectedInternalGroup,
        ]
        expectedMainGroup.addChildren(expectedRootElements)

        expectedPBXProj.rootObject!.knownRegions = ["en", "es", "Base"]

        // Act

        let (
            createdFiles,
            createdRootElements,
            _,
            _,
            internalFiles,
            _,
            _
        ) = try Generator.createFilesAndGroups(
            in: pbxProj,
            buildMode: .bazel,
            forFixtures: false,
            targets: targets,
            extraFiles: extraFiles,
            xccurrentversions: xccurrentversions,
            directories: directories,
            logger: StubLogger()
        )

        // We need to add the `rootElements` to a group to allow references to
        // become fixed
        mainGroup.addChildren(createdRootElements)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdRootElements, expectedRootElements)
        XCTAssertNoDifference(
            createdFiles.map(KeyAndValue.init).sorted(),
            expectedFiles.map(KeyAndValue.init).sorted()
        )
        XCTAssertNoDifference(
            internalFiles.map(KeyAndValue.init).sorted(),
            expectedInternalFiles.map(KeyAndValue.init).sorted()
        )

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}

struct KeyAndValue<Key, Value> {
    let key: Key
    let value: Value

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

extension KeyAndValue: Equatable where Key: Equatable, Value: Equatable {}
extension KeyAndValue: Hashable where Key: Hashable, Value: Hashable {}
extension KeyAndValue: Comparable where Key: Comparable, Value: Equatable {
    static func < (lhs: KeyAndValue, rhs: KeyAndValue) -> Bool {
        return lhs.key < rhs.key
    }
}
