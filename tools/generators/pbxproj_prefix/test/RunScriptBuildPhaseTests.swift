import CustomDump
import PBXProj
import XCTest

@testable import pbxproj_prefix

class RunScriptBuildPhaseTests: XCTestCase {
    func test() {
        // Arrange

        let name = "Wild and Crazy"
        let script = #"""
set -euo pipefail

if [[ "$ACTION" == "indexbuild" ]]; then
  cd "$SRCROOT"

  "$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh"
else
  "$BAZEL_INTEGRATION_DIR/copy_outputs.sh" \
    "_BazelForcedCompile_.swift" \
    "watchOSApp.app" \
    "$BAZEL_INTEGRATION_DIR/watchos2_app.exclude.rsynclist"
fi

"""#

        // The tabs for indenting are intentional
        let expectedRunScriptBuildPhase = #"""
{
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Wild and Crazy Run Script";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"$ACTION\" == \"indexbuild\" ]]; then\n  cd \"$SRCROOT\"\n\n  \"$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh\"\nelse\n  \"$BAZEL_INTEGRATION_DIR/copy_outputs.sh\" \\\n    \"_BazelForcedCompile_.swift\" \\\n    \"watchOSApp.app\" \\\n    \"$BAZEL_INTEGRATION_DIR/watchos2_app.exclude.rsynclist\"\nfi\n";
			showEnvVarsInLog = 0;
		}
"""#

        // Act

        let runScriptBuildPhase = Generator.runScriptBuildPhase(
            name: name,
            script: script
        )

        // Assert

        XCTAssertNoDifference(runScriptBuildPhase, expectedRunScriptBuildPhase)
    }
}
