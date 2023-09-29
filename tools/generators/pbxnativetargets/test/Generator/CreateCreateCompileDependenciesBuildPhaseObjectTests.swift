import CustomDump
import ToolCommon
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateCreateCompileDependenciesBuildPhaseObjectTests: XCTestCase {
    func test_none() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let hasCParams = false
        let hasCxxParams = false

        // Act

        let object = Generator.CreateCreateCompileDependenciesBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                hasCParams: hasCParams,
                hasCxxParams: hasCxxParams
            )

        // Assert

        XCTAssertNil(object)
    }

    func test_params() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let hasCParams = true
        let hasCxxParams = true

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000004 /* Create Compile Dependencies */
"""#,
            content: #"""
{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(C_PARAMS_FILE)",
				"$(CXX_PARAMS_FILE)",
			);
			name = "Create Compile Dependencies";
			outputPaths = (
				"$(DERIVED_FILE_DIR)/c.compile.params",
				"$(DERIVED_FILE_DIR)/cxx.compile.params",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nperl -pe '\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n  s/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/gx;\n' \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\n\nperl -pe '\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n  s/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/gx;\n' \"$SCRIPT_INPUT_FILE_1\" > \"$SCRIPT_OUTPUT_FILE_1\"\n";
			showEnvVarsInLog = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateCreateCompileDependenciesBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                hasCParams: hasCParams,
                hasCxxParams: hasCxxParams
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
