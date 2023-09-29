import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateBazelIntegrationBuildPhaseObjectTests: XCTestCase {
    func test_basic() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let productType = PBXProductType.commandLineTool

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000003 \#
/* Copy Bazel Outputs / Generate Bazel Dependencies (Index Build) */
"""#,
            content: #"""
{
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Copy Bazel Outputs / Generate Bazel Dependencies (Index Build)";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"$ACTION\" == \"indexbuild\" ]]; then\n  cd \"$SRCROOT\"\n\n  \"$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh\"\nelse\n  \"$BAZEL_INTEGRATION_DIR/copy_outputs.sh\" \\\n    \"_BazelForcedCompile_.swift\" \\\n    \"\"\nfi\n";
			showEnvVarsInLog = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateBazelIntegrationBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                productType: productType
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }

    func test_infoPlist() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let productType = PBXProductType.application

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000003 \#
/* Copy Bazel Outputs / Generate Bazel Dependencies (Index Build) */
"""#,
            content: #"""
{
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)",
			);
			name = "Copy Bazel Outputs / Generate Bazel Dependencies (Index Build)";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"$ACTION\" == \"indexbuild\" ]]; then\n  cd \"$SRCROOT\"\n\n  \"$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh\"\nelse\n  \"$BAZEL_INTEGRATION_DIR/copy_outputs.sh\" \\\n    \"_BazelForcedCompile_.swift\" \\\n    \"$BAZEL_INTEGRATION_DIR/app.exclude.rsynclist\"\nfi\n";
			showEnvVarsInLog = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateBazelIntegrationBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                productType: productType
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
