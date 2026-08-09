import CustomDump
import ToolCommon
import XCTest
@testable import pbxnativetargets
@testable import PBXProj

// Serialized PBX shell scripts are intentionally represented as one line.
// swiftlint:disable line_length
class CreateCreateLinkDependenciesBuildPhaseObjectTests: XCTestCase {
    func test_base() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let hasCompileStub = false

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000005 /* Create Link Dependencies */
"""#,
            content: #"""
{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(LINK_PARAMS_FILE)",
			);
			name = "Create Link Dependencies";
			outputPaths = (
				"$(DERIVED_FILE_DIR)/link.params",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"${ENABLE_PREVIEWS:-}\" == \"YES\" || \\\n      \"${ENABLE_XOJIT_PREVIEWS:-}\" == \"YES\" ]]; then\nreadonly link_params_tmp=\"$(mktemp \"$SCRIPT_OUTPUT_FILE_0.tmp.XXXXXX\")\"\ntrap 'rm -f \"$link_params_tmp\"' EXIT\nperl -pe 's/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/g' \\\n  \"$SCRIPT_INPUT_FILE_0\" > \"$link_params_tmp\"\nchmod 0644 \"$link_params_tmp\"\nmv -f \"$link_params_tmp\" \"$SCRIPT_OUTPUT_FILE_0\"\ntrap - EXIT\nelse\n  # A prior Preview build may have populated this response file. Truncate it\n  # so ordinary linker and Libtool tasks cannot consume stale Preview inputs.\n  : > \"$SCRIPT_OUTPUT_FILE_0\"\nfi\n";
			showEnvVarsInLog = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateCreateLinkDependenciesBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                hasCompileStub: hasCompileStub
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }

    func test_hasCompileStub() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let hasCompileStub = true

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000005 /* Create Link Dependencies */
"""#,
            content: #"""
{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(LINK_PARAMS_FILE)",
			);
			name = "Create Link Dependencies";
			outputPaths = (
				"$(DERIVED_FILE_DIR)/link.params",
				"$(DERIVED_FILE_DIR)/_CompileStub_.m",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"${ENABLE_PREVIEWS:-}\" == \"YES\" || \\\n      \"${ENABLE_XOJIT_PREVIEWS:-}\" == \"YES\" ]]; then\nreadonly link_params_tmp=\"$(mktemp \"$SCRIPT_OUTPUT_FILE_0.tmp.XXXXXX\")\"\ntrap 'rm -f \"$link_params_tmp\"' EXIT\nperl -pe 's/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/g' \\\n  \"$SCRIPT_INPUT_FILE_0\" > \"$link_params_tmp\"\nchmod 0644 \"$link_params_tmp\"\nmv -f \"$link_params_tmp\" \"$SCRIPT_OUTPUT_FILE_0\"\ntrap - EXIT\nelse\n  # A prior Preview build may have populated this response file. Truncate it\n  # so ordinary linker and Libtool tasks cannot consume stale Preview inputs.\n  : > \"$SCRIPT_OUTPUT_FILE_0\"\nfi\n\ntouch \"$SCRIPT_OUTPUT_FILE_1\"\n";
			showEnvVarsInLog = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateCreateLinkDependenciesBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                hasCompileStub: hasCompileStub
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}

// swiftlint:enable line_length
