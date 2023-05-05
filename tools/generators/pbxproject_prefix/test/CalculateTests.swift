import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import pbxproject_prefix

class CalculateTests: XCTestCase {
    func test_noOrganizationName() {
        // Arrange

        let compatibilityVersion = "AppCode 42.7.4"
        let developmentRegion = "en-GB"
        let organizationName: String? = nil
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"

        // The tabs for indenting are intentional
        let expectedPBXProjectPrefix = #"""
		000000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = 000000000000000000000002 /* Build configuration list for PBXProject */;
			compatibilityVersion = "AppCode 42.7.4";
			developmentRegion = "en-GB";
			hasScannedForEncodings = 0;
			mainGroup = 000000000000000000000003 /* /Users/TimApple/StarBoard */;
			productRefGroup = 000000000000000000000004 /* Products */;
			projectDirPath = /some/execution_root;
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;

"""#

        // Act

        let projectPrefix = Generator.calculate(
            compatibilityVersion: compatibilityVersion,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(projectPrefix, expectedPBXProjectPrefix)
    }

    func test_organizationName_simple() {
        // Arrange

        let compatibilityVersion = "AppCode 42.7.4"
        let developmentRegion = "enGB"
        let organizationName = "SingleWord"
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"

        let expectedPBXProjectPrefix = #"""
		000000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = 000000000000000000000002 /* Build configuration list for PBXProject */;
			compatibilityVersion = "AppCode 42.7.4";
			developmentRegion = enGB;
			hasScannedForEncodings = 0;
			mainGroup = 000000000000000000000003 /* /Users/TimApple/StarBoard */;
			productRefGroup = 000000000000000000000004 /* Products */;
			projectDirPath = /some/execution_root;
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;
				ORGANIZATIONNAME = SingleWord;

"""#

        // Act

        let projectPrefix = Generator.calculate(
            compatibilityVersion: compatibilityVersion,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(projectPrefix, expectedPBXProjectPrefix)
    }

    func test_organizationName_space() {
        // Arrange

        let compatibilityVersion = "AppCode 42.7.4"
        let developmentRegion = "enGB"
        let organizationName = "Multiple Words"
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"

        let expectedPBXProjectPrefix = #"""
		000000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = 000000000000000000000002 /* Build configuration list for PBXProject */;
			compatibilityVersion = "AppCode 42.7.4";
			developmentRegion = enGB;
			hasScannedForEncodings = 0;
			mainGroup = 000000000000000000000003 /* /Users/TimApple/StarBoard */;
			productRefGroup = 000000000000000000000004 /* Products */;
			projectDirPath = /some/execution_root;
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;
				ORGANIZATIONNAME = "Multiple Words";

"""#

        // Act

        let projectPrefix = Generator.calculate(
            compatibilityVersion: compatibilityVersion,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(projectPrefix, expectedPBXProjectPrefix)
    }

    func test_organizationName_escaped() {
        // Arrange

        let compatibilityVersion = "AppCode 42.7.4"
        let developmentRegion = "enGB"
        let organizationName = #"Go "Home""#
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"

        let expectedPBXProjectPrefix = #"""
		000000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = 000000000000000000000002 /* Build configuration list for PBXProject */;
			compatibilityVersion = "AppCode 42.7.4";
			developmentRegion = enGB;
			hasScannedForEncodings = 0;
			mainGroup = 000000000000000000000003 /* /Users/TimApple/StarBoard */;
			productRefGroup = 000000000000000000000004 /* Products */;
			projectDirPath = /some/execution_root;
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;
				ORGANIZATIONNAME = "Go \"Home\"";

"""#

        // Act

        let projectPrefix = Generator.calculate(
            compatibilityVersion: compatibilityVersion,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(projectPrefix, expectedPBXProjectPrefix)
    }
}
