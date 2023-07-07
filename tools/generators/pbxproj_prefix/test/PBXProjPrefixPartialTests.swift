import CustomDump
import Foundation
import GeneratorCommon
import PBXProj
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
            minimumXcodeVersion: minimumXcodeVersion
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
            minimumXcodeVersion: minimumXcodeVersion
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
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }

    func test_xcode42() {
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
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }
}
