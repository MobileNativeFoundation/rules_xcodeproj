import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateAttributesTests: XCTestCase {

    // MARK: - resolvedRepository

    func test_resolvedRepository_symlink_legacyBazelExternal() {
        // Arrange

        let name = "a"
        let bazelPath: BazelPath = "external/a"
        let isGroup = true
        let specialRootGroupType: SpecialRootGroupType = .legacyBazelExternal
        let resolveSymlink = ElementCreator.ResolveSymlink.stub(
            symlinkDest: "/tmp/a"
        )

        let expectedResolvedRepository = ResolvedRepository(
            sourcePath: "./external/a",
            mappedPath: "/tmp/a"
        )

        // Act

        let result = ElementCreator.CreateAttributes.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            isGroup: isGroup,
            specialRootGroupType: specialRootGroupType,
            executionRoot: "/tmp/execroot",
            externalDir: "/tmp/execroot/external",
            workspace: "/tmp/workspace",
            resolveSymlink: resolveSymlink
        )

        // Assert

        XCTAssertNoDifference(
            result.resolvedRepository,
            expectedResolvedRepository
        )
    }

    func test_resolvedRepository_symlink_siblingBazelExternal() {
        // Arrange

        let name = "b"
        let bazelPath: BazelPath = "../b"
        let isGroup = true
        let specialRootGroupType: SpecialRootGroupType = .siblingBazelExternal
        let resolveSymlink = ElementCreator.ResolveSymlink.stub(
            symlinkDest: "/tmp/b"
        )

        let expectedResolvedRepository = ResolvedRepository(
            sourcePath: "../b",
            mappedPath: "/tmp/b"
        )

        // Act

        let result = ElementCreator.CreateAttributes.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            isGroup: isGroup,
            specialRootGroupType: specialRootGroupType,
            executionRoot: "/tmp/execroot",
            externalDir: "/tmp/execroot/external",
            workspace: "/tmp/workspace",
            resolveSymlink: resolveSymlink
        )

        // Assert

        XCTAssertNoDifference(
            result.resolvedRepository,
            expectedResolvedRepository
        )
    }

    func test_resolvedRepository_symlink_notGroup() {
        // Arrange

        let name = "c"
        let bazelPath: BazelPath = "external/c"
        let isGroup = false
        let specialRootGroupType: SpecialRootGroupType = .legacyBazelExternal
        let resolveSymlink = ElementCreator.ResolveSymlink.stub(
            symlinkDest: "/tmp/c"
        )

        // Act

        let result = ElementCreator.CreateAttributes.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            isGroup: isGroup,
            specialRootGroupType: specialRootGroupType,
            executionRoot: "/tmp/execroot",
            externalDir: "/tmp/execroot/external",
            workspace: "/tmp/workspace",
            resolveSymlink: resolveSymlink
        )

        // Assert

        XCTAssertNil(result.resolvedRepository)
    }

    func test_resolvedRepository_symlink_bazelGenerated() {
        // Arrange

        let name = "d"
        let bazelPath: BazelPath = "bazel-out/d"
        let isGroup = true
        let specialRootGroupType: SpecialRootGroupType = .bazelGenerated
        let resolveSymlink = ElementCreator.ResolveSymlink.stub(
            symlinkDest: "/tmp/d"
        )

        // Act

        let result = ElementCreator.CreateAttributes.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            isGroup: isGroup,
            specialRootGroupType: specialRootGroupType,
            executionRoot: "/tmp/execroot",
            externalDir: "/tmp/execroot/external",
            workspace: "/tmp/workspace",
            resolveSymlink: resolveSymlink
        )

        // Assert

        XCTAssertNil(result.resolvedRepository)
    }

    func test_resolvedRepository_notSymlink() {
        // Arrange

        let name = "e"
        let bazelPath: BazelPath = "external/e"
        let isGroup = true
        let specialRootGroupType: SpecialRootGroupType = .legacyBazelExternal
        let resolveSymlink = ElementCreator.ResolveSymlink.stub(
            symlinkDest: nil
        )

        // Act

        let result = ElementCreator.CreateAttributes.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            isGroup: isGroup,
            specialRootGroupType: specialRootGroupType,
            executionRoot: "/tmp/execroot",
            externalDir: "/tmp/execroot/external",
            workspace: "/tmp/workspace",
            resolveSymlink: resolveSymlink
        )

        // Assert

        XCTAssertNil(result.resolvedRepository)
    }
}
