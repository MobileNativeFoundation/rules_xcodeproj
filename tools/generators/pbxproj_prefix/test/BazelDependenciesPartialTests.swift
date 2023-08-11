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
		FF0100000000000000000005 /* Create swift_debug_settings.py */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py",
			);
			name = "Create swift_debug_settings.py";
			outputPaths = (
				"$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "perl -pe '\n  # Replace \"__BAZEL_XCODE_DEVELOPER_DIR__\" with \"$(DEVELOPER_DIR)\"\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n\n  # Replace \"__BAZEL_XCODE_SDKROOT__\" with \"$(SDKROOT)\"\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n\n  # Replace build settings with their values\n  s/\n    \\$             # Match a dollar sign\n    (\\()?          # Optionally match an opening parenthesis and capture it\n    ([a-zA-Z_]\\w*) # Match a variable name and capture it\n    (?(1)\\))       # If an opening parenthesis was captured, match a closing parenthesis\n  /$ENV{$2}/gx;    # Replace the entire matched string with the value of the corresponding environment variable\n\n' \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\n";
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
				FF0100000000000000000005 /* Create swift_debug_settings.py */,
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
		FF0100000000000000000005 /* Create swift_debug_settings.py */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py",
			);
			name = "Create swift_debug_settings.py";
			outputPaths = (
				"$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "perl -pe '\n  # Replace \"__BAZEL_XCODE_DEVELOPER_DIR__\" with \"$(DEVELOPER_DIR)\"\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n\n  # Replace \"__BAZEL_XCODE_SDKROOT__\" with \"$(SDKROOT)\"\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n\n  # Replace build settings with their values\n  s/\n    \\$             # Match a dollar sign\n    (\\()?          # Optionally match an opening parenthesis and capture it\n    ([a-zA-Z_]\\w*) # Match a variable name and capture it\n    (?(1)\\))       # If an opening parenthesis was captured, match a closing parenthesis\n  /$ENV{$2}/gx;    # Replace the entire matched string with the value of the corresponding environment variable\n\n' \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\n";
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
				FF0100000000000000000005 /* Create swift_debug_settings.py */,
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
		FF0100000000000000000005 /* Create swift_debug_settings.py */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py",
			);
			name = "Create swift_debug_settings.py";
			outputPaths = (
				"$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "perl -pe '\n  # Replace \"__BAZEL_XCODE_DEVELOPER_DIR__\" with \"$(DEVELOPER_DIR)\"\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n\n  # Replace \"__BAZEL_XCODE_SDKROOT__\" with \"$(SDKROOT)\"\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n\n  # Replace build settings with their values\n  s/\n    \\$             # Match a dollar sign\n    (\\()?          # Optionally match an opening parenthesis and capture it\n    ([a-zA-Z_]\\w*) # Match a variable name and capture it\n    (?(1)\\))       # If an opening parenthesis was captured, match a closing parenthesis\n  /$ENV{$2}/gx;    # Replace the entire matched string with the value of the corresponding environment variable\n\n' \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\n";
			showEnvVarsInLog = 0;
		};
		FF0100000000000000000006 /* Post-build Run Script */ = {POST_BUILD_HERE};
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
				FF0100000000000000000005 /* Create swift_debug_settings.py */,
				FF0100000000000000000006 /* Post-build Run Script */,
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
		FF0100000000000000000005 /* Create swift_debug_settings.py */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py",
			);
			name = "Create swift_debug_settings.py";
			outputPaths = (
				"$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "perl -pe '\n  # Replace \"__BAZEL_XCODE_DEVELOPER_DIR__\" with \"$(DEVELOPER_DIR)\"\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n\n  # Replace \"__BAZEL_XCODE_SDKROOT__\" with \"$(SDKROOT)\"\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n\n  # Replace build settings with their values\n  s/\n    \\$             # Match a dollar sign\n    (\\()?          # Optionally match an opening parenthesis and capture it\n    ([a-zA-Z_]\\w*) # Match a variable name and capture it\n    (?(1)\\))       # If an opening parenthesis was captured, match a closing parenthesis\n  /$ENV{$2}/gx;    # Replace the entire matched string with the value of the corresponding environment variable\n\n' \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\n";
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
				FF0100000000000000000005 /* Create swift_debug_settings.py */,
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
