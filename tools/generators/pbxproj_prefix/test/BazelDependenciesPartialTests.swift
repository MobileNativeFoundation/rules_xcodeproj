import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import pbxproj_prefix

class BazelDependenciesPartialTests: XCTestCase {
    func test_noOptionalValues() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let defaultXcodeConfiguration = "Debug"
        let postBuildRunScript: String? = nil
        let preBuildRunScript: String? = nil
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Debug",
        ]

        // The tabs for indenting are intentional.
        // Order of configurations is wrong, but shows that it doesn't do
        // sorting (since they should be sorted coming in).
        let expectedBazelDependencies = #"""
		FF0100000000000000000004 /* Bazel Build */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Generate Bazel Dependendencies";
			outputFileListPaths = (
				"$(INTERNAL_DIR)/external.xcfilelist",
				"$(INTERNAL_DIR)/generated.xcfilelist",
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh\"\n";
			showEnvVarsInLog = 0;
		};
		FF0100000000000000000100 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		FF0100000000000000000101 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		FF0100000000000000000102 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				FF0100000000000000000100 /* Release */,
				FF0100000000000000000101 /* Profile */,
				FF0100000000000000000102 /* Debug */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				FF0100000000000000000004 /* Bazel Build */,
			);
			dependencies = (
			);
			name = BazelDependencies;
			productName = BazelDependencies;
		};

"""#

        // Act

        let bazelDependencies = Generator.bazelDependenciesPartial(
            buildSettings: buildSettings,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            postBuildRunScript: postBuildRunScript,
            preBuildRunScript: preBuildRunScript,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(bazelDependencies, expectedBazelDependencies)
    }

    func test_defaultXcodeConfiguration() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let defaultXcodeConfiguration = "Profile"
        let postBuildRunScript: String? = nil
        let preBuildRunScript: String? = nil
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Debug",
        ]

        // The tabs for indenting are intentional.
        // Order of configurations is wrong, but shows that it doesn't do
        // sorting (since they should be sorted coming in).
        let expectedBazelDependencies = #"""
		FF0100000000000000000004 /* Bazel Build */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Generate Bazel Dependendencies";
			outputFileListPaths = (
				"$(INTERNAL_DIR)/external.xcfilelist",
				"$(INTERNAL_DIR)/generated.xcfilelist",
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh\"\n";
			showEnvVarsInLog = 0;
		};
		FF0100000000000000000100 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		FF0100000000000000000101 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		FF0100000000000000000102 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				FF0100000000000000000100 /* Release */,
				FF0100000000000000000101 /* Profile */,
				FF0100000000000000000102 /* Debug */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Profile;
		};
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				FF0100000000000000000004 /* Bazel Build */,
			);
			dependencies = (
			);
			name = BazelDependencies;
			productName = BazelDependencies;
		};

"""#

        // Act

        let bazelDependencies = Generator.bazelDependenciesPartial(
            buildSettings: buildSettings,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            postBuildRunScript: postBuildRunScript,
            preBuildRunScript: preBuildRunScript,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(bazelDependencies, expectedBazelDependencies)
    }

    func test_postBuildRunScript() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let defaultXcodeConfiguration = "Debug"
        let postBuildRunScript = "{POST_BUILD_HERE}"
        let preBuildRunScript: String? = nil
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Debug",
        ]

        // The tabs for indenting are intentional.
        // Order of configurations is wrong, but shows that it doesn't do
        // sorting (since they should be sorted coming in).
        let expectedBazelDependencies = #"""
		FF0100000000000000000004 /* Bazel Build */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Generate Bazel Dependendencies";
			outputFileListPaths = (
				"$(INTERNAL_DIR)/external.xcfilelist",
				"$(INTERNAL_DIR)/generated.xcfilelist",
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh\"\n";
			showEnvVarsInLog = 0;
		};
		FF0100000000000000000005 /* Post-build Run Script */ = {POST_BUILD_HERE};
		FF0100000000000000000100 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		FF0100000000000000000101 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		FF0100000000000000000102 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				FF0100000000000000000100 /* Release */,
				FF0100000000000000000101 /* Profile */,
				FF0100000000000000000102 /* Debug */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				FF0100000000000000000004 /* Bazel Build */,
				FF0100000000000000000005 /* Post-build Run Script */,
			);
			dependencies = (
			);
			name = BazelDependencies;
			productName = BazelDependencies;
		};

"""#

        // Act

        let bazelDependencies = Generator.bazelDependenciesPartial(
            buildSettings: buildSettings,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            postBuildRunScript: postBuildRunScript,
            preBuildRunScript: preBuildRunScript,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(bazelDependencies, expectedBazelDependencies)
    }

    func test_preBuildRunScript() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let defaultXcodeConfiguration = "Debug"
        let postBuildRunScript: String? = nil
        let preBuildRunScript = "{PRE_BUILD_HERE}"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Debug",
        ]

        // The tabs for indenting are intentional.
        // Order of configurations is wrong, but shows that it doesn't do
        // sorting (since they should be sorted coming in).
        let expectedBazelDependencies = #"""
		FF0100000000000000000003 /* Pre-build Run Script */ = {PRE_BUILD_HERE};
		FF0100000000000000000004 /* Bazel Build */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Generate Bazel Dependendencies";
			outputFileListPaths = (
				"$(INTERNAL_DIR)/external.xcfilelist",
				"$(INTERNAL_DIR)/generated.xcfilelist",
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh\"\n";
			showEnvVarsInLog = 0;
		};
		FF0100000000000000000100 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		FF0100000000000000000101 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		FF0100000000000000000102 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				FF0100000000000000000100 /* Release */,
				FF0100000000000000000101 /* Profile */,
				FF0100000000000000000102 /* Debug */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				FF0100000000000000000003 /* Pre-build Run Script */,
				FF0100000000000000000004 /* Bazel Build */,
			);
			dependencies = (
			);
			name = BazelDependencies;
			productName = BazelDependencies;
		};

"""#

        // Act

        let bazelDependencies = Generator.bazelDependenciesPartial(
            buildSettings: buildSettings,
            defaultXcodeConfiguration: defaultXcodeConfiguration,
            postBuildRunScript: postBuildRunScript,
            preBuildRunScript: preBuildRunScript,
            xcodeConfigurations: xcodeConfigurations
        )

        // Assert

        XCTAssertNoDifference(bazelDependencies, expectedBazelDependencies)
    }
}
