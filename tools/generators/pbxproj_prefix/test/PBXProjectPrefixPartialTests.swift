import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import pbxproj_prefix

class PBXProjectPrefixPartialTests: XCTestCase {
    func test_defaultXcodeConfiguration() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let compatibilityVersion = "AppCode 42.7.4"
        let defaultXcodeConfiguration = "Profile"
        let developmentRegion = "en-GB"
        let organizationName: String? = nil
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        // The tabs for indenting are intentional
        let expectedPBXProjectPrefixPartial = #"""
		000000000000000000000008 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		000000000000000000000009 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		00000000000000000000000A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		000000000000000000000002 /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000008 /* Debug */,
				000000000000000000000009 /* Profile */,
				00000000000000000000000A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Profile;
		};
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

        let pbxProjectPrefixPartial = Generator.pbxProjectPrefixPartial(
            buildSettings: buildSettings,
            compatibilityVersion: compatibilityVersion,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjectPrefixPartial,
            expectedPBXProjectPrefixPartial
        )
    }

    func test_noOrganizationName() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let compatibilityVersion = "AppCode 42.7.4"
        let defaultXcodeConfiguration: String? = nil
        let developmentRegion = "en-GB"
        let organizationName: String? = nil
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        // The tabs for indenting are intentional
        let expectedPBXProjectPrefixPartial = #"""
		000000000000000000000008 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		000000000000000000000009 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		00000000000000000000000A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		000000000000000000000002 /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000008 /* Debug */,
				000000000000000000000009 /* Profile */,
				00000000000000000000000A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
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

        let pbxProjectPrefixPartial = Generator.pbxProjectPrefixPartial(
            buildSettings: buildSettings,
            compatibilityVersion: compatibilityVersion,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjectPrefixPartial,
            expectedPBXProjectPrefixPartial
        )
    }

    func test_organizationName_simple() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let compatibilityVersion = "AppCode 42.7.4"
        let defaultXcodeConfiguration: String? = nil
        let developmentRegion = "enGB"
        let organizationName = "SingleWord"
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        let expectedPBXProjectPrefixPartial = #"""
		000000000000000000000008 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		000000000000000000000009 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		00000000000000000000000A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		000000000000000000000002 /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000008 /* Debug */,
				000000000000000000000009 /* Profile */,
				00000000000000000000000A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
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

        let pbxProjectPrefixPartial = Generator.pbxProjectPrefixPartial(
            buildSettings: buildSettings,
            compatibilityVersion: compatibilityVersion,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjectPrefixPartial,
            expectedPBXProjectPrefixPartial
        )
    }

    func test_organizationName_space() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let compatibilityVersion = "AppCode 42.7.4"
        let defaultXcodeConfiguration: String? = nil
        let developmentRegion = "enGB"
        let organizationName = "Multiple Words"
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        let expectedPBXProjectPrefixPartial = #"""
		000000000000000000000008 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		000000000000000000000009 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		00000000000000000000000A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		000000000000000000000002 /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000008 /* Debug */,
				000000000000000000000009 /* Profile */,
				00000000000000000000000A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
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

        let pbxProjectPrefixPartial = Generator.pbxProjectPrefixPartial(
            buildSettings: buildSettings,
            compatibilityVersion: compatibilityVersion,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjectPrefixPartial,
            expectedPBXProjectPrefixPartial
        )
    }

    func test_organizationName_escaped() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let compatibilityVersion = "AppCode 42.7.4"
        let defaultXcodeConfiguration: String? = nil
        let developmentRegion = "enGB"
        let organizationName = #"Go "Home""#
        let projectDir = "/some/execution_root"
        let workspace = "/Users/TimApple/StarBoard"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        let expectedPBXProjectPrefixPartial = #"""
		000000000000000000000008 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		000000000000000000000009 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		00000000000000000000000A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		000000000000000000000002 /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000008 /* Debug */,
				000000000000000000000009 /* Profile */,
				00000000000000000000000A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
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

        let pbxProjectPrefixPartial = Generator.pbxProjectPrefixPartial(
            buildSettings: buildSettings,
            compatibilityVersion: compatibilityVersion,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            developmentRegion: developmentRegion,
            organizationName: organizationName,
            projectDir: projectDir,
            workspace: workspace,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjectPrefixPartial,
            expectedPBXProjectPrefixPartial
        )
    }
}
