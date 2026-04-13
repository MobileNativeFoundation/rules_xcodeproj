import CustomDump
import Foundation
import PBXProj
import ToolCommon
import XCTest

@testable import pbxproj_prefix

class PBXProjPrefixPartialTests: XCTestCase {
    func test_xcode13() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "13.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 55;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: false
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode14() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "14.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: false
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode15() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "15.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 60;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: false
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode16_withoutBuildableFolders() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "16.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 60;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: false
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode16_withBuildableFolders() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "16.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: true
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode42_withoutBuildableFolders() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "42.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 60;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: false
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode42_withBuildableFolders() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"
        let minimumXcodeVersion: SemanticVersion = "42.0"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial,
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: true
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }
}
