import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import pbxproj_prefix

class BazelDependenciesPartialTests: XCTestCase {
    func test_noOptionalValues() {
        // Arrange

        let buildSettings = "{BUILD_SETTINGS_HERE}"
        let defaultXcodeConfiguration: String? = nil
        let postBuildRunScript: String? = nil
        let preBuildRunScript: String? = nil
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        // The tabs for indenting are intentional
        let expectedBazelDependencies = #"""
		0000000000000000000000FD /* Bazel Build */ = {
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
		0000000000000000000000FC /* Create swift_debug_settings.py */ = {
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
		0000000000000000000000F9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		0000000000000000000000F8 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		0000000000000000000000F7 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0000000000000000000000F9 /* Debug */,
				0000000000000000000000F8 /* Profile */,
				0000000000000000000000F7 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		0000000000000000000000FF /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = 0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				0000000000000000000000FD /* Bazel Build */,
				0000000000000000000000FC /* Create swift_debug_settings.py */,
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
            "Release",
            "Debug",
        ]

        // The tabs for indenting are intentional
        let expectedBazelDependencies = #"""
		0000000000000000000000FD /* Bazel Build */ = {
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
		0000000000000000000000FC /* Create swift_debug_settings.py */ = {
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
		0000000000000000000000F9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		0000000000000000000000F8 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		0000000000000000000000F7 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0000000000000000000000F9 /* Debug */,
				0000000000000000000000F8 /* Profile */,
				0000000000000000000000F7 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Profile;
		};
		0000000000000000000000FF /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = 0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				0000000000000000000000FD /* Bazel Build */,
				0000000000000000000000FC /* Create swift_debug_settings.py */,
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
        let defaultXcodeConfiguration: String? = nil
        let postBuildRunScript = "{POST_BUILD_HERE}"
        let preBuildRunScript: String? = nil
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        // The tabs for indenting are intentional
        let expectedBazelDependencies = #"""
		0000000000000000000000FD /* Bazel Build */ = {
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
		0000000000000000000000FC /* Create swift_debug_settings.py */ = {
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
		0000000000000000000000FB /* Post-build Run Script */ = {POST_BUILD_HERE};
		0000000000000000000000F9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		0000000000000000000000F8 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		0000000000000000000000F7 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0000000000000000000000F9 /* Debug */,
				0000000000000000000000F8 /* Profile */,
				0000000000000000000000F7 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		0000000000000000000000FF /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = 0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				0000000000000000000000FD /* Bazel Build */,
				0000000000000000000000FC /* Create swift_debug_settings.py */,
				0000000000000000000000FB /* Post-build Run Script */,
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
        let defaultXcodeConfiguration: String? = nil
        let postBuildRunScript: String? = nil
        let preBuildRunScript = "{PRE_BUILD_HERE}"
        let xcodeConfigurations = [
            "Release",
            "Profile",
            "Release",
            "Debug",
        ]

        // The tabs for indenting are intentional
        let expectedBazelDependencies = #"""
		0000000000000000000000FE /* Pre-build Run Script */ = {PRE_BUILD_HERE};
		0000000000000000000000FD /* Bazel Build */ = {
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
		0000000000000000000000FC /* Create swift_debug_settings.py */ = {
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
		0000000000000000000000F9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Debug;
		};
		0000000000000000000000F8 /* Profile */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Profile;
		};
		0000000000000000000000F7 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS_HERE};
			name = Release;
		};
		0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0000000000000000000000F9 /* Debug */,
				0000000000000000000000F8 /* Profile */,
				0000000000000000000000F7 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		0000000000000000000000FF /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = 0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				0000000000000000000000FE /* Pre-build Run Script */,
				0000000000000000000000FD /* Bazel Build */,
				0000000000000000000000FC /* Create swift_debug_settings.py */,
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
