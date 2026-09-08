import CustomDump
import Foundation
import ToolCommon
import XCTest
@testable import pbxnativetargets
@testable import PBXProj

// Serialized PBX shell scripts are intentionally represented as one line.
// swiftlint:disable line_length
class CreateCreateLinkDependenciesBuildPhaseObjectTests: XCTestCase {
    private let previewModes = [
        ["ENABLE_PREVIEWS": "YES", "BAZEL_NATIVE_PREVIEWS": "NO"],
        ["ENABLE_PREVIEWS": "NO", "BAZEL_NATIVE_PREVIEWS": "YES"],
    ]

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
			shellScript = "set -euo pipefail\n\nif [[ \"${ENABLE_PREVIEWS:-}\" == \"YES\" || \\\n      \"${BAZEL_NATIVE_PREVIEWS:-}\" == \"YES\" ]]; then\nreadonly link_params_tmp=\"$(mktemp \"$SCRIPT_OUTPUT_FILE_0.tmp.XXXXXX\")\"\ntrap 'rm -f \"$link_params_tmp\"' EXIT\nperl -pe 's/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/g' \\\n  < \"$SCRIPT_INPUT_FILE_0\" > \"$link_params_tmp\"\nchmod 0644 \"$link_params_tmp\"\nmv -f \"$link_params_tmp\" \"$SCRIPT_OUTPUT_FILE_0\"\ntrap - EXIT\nelse\n  # A prior Preview build may have populated this response file. Truncate it\n  # so ordinary linker and Libtool tasks cannot consume stale Preview inputs.\n  : > \"$SCRIPT_OUTPUT_FILE_0\"\nfi\n";
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
			shellScript = "set -euo pipefail\n\nif [[ \"${ENABLE_PREVIEWS:-}\" == \"YES\" || \\\n      \"${BAZEL_NATIVE_PREVIEWS:-}\" == \"YES\" ]]; then\nreadonly link_params_tmp=\"$(mktemp \"$SCRIPT_OUTPUT_FILE_0.tmp.XXXXXX\")\"\ntrap 'rm -f \"$link_params_tmp\"' EXIT\nperl -pe 's/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/g' \\\n  < \"$SCRIPT_INPUT_FILE_0\" > \"$link_params_tmp\"\nchmod 0644 \"$link_params_tmp\"\nmv -f \"$link_params_tmp\" \"$SCRIPT_OUTPUT_FILE_0\"\ntrap - EXIT\nelse\n  # A prior Preview build may have populated this response file. Truncate it\n  # so ordinary linker and Libtool tasks cannot consume stale Preview inputs.\n  : > \"$SCRIPT_OUTPUT_FILE_0\"\nfi\n\ntouch \"$SCRIPT_OUTPUT_FILE_1\"\n";
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

    func test_missingPreviewInputPreservesResponse() throws {
        for previewSettings in previewModes {
            for hasCompileStub in [false, true] {
                let directory = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                defer { try? FileManager.default.removeItem(at: directory) }

                let output = directory.appendingPathComponent("link.params")
                try "previous response\n".write(
                    to: output,
                    atomically: true,
                    encoding: .utf8
                )

                let status = try runScript(
                    directory: directory,
                    previewSettings: previewSettings,
                    hasCompileStub: hasCompileStub
                )

                XCTAssertNotEqual(status, 0)
                XCTAssertEqual(
                    try String(contentsOf: output),
                    "previous response\n"
                )
                XCTAssertEqual(
                    try FileManager.default.contentsOfDirectory(
                        atPath: directory.path
                    ).sorted(),
                    ["link.params"]
                )
            }
        }
    }

    func test_previewInputExpandsResponse() throws {
        for previewSettings in previewModes {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            defer { try? FileManager.default.removeItem(at: directory) }

            try "-L$(PROJECT_DIR)/libraries\n".write(
                to: directory.appendingPathComponent("input.params"),
                atomically: true,
                encoding: .utf8
            )
            XCTAssertEqual(
                try runScript(
                    directory: directory,
                    previewSettings: previewSettings,
                    hasCompileStub: true
                ),
                0
            )
            XCTAssertEqual(
                try String(
                    contentsOf: directory.appendingPathComponent("link.params")
                ),
                "-L/source root/libraries\n"
            )
            XCTAssertEqual(
                try FileManager.default.contentsOfDirectory(
                    atPath: directory.path
                ).sorted(),
                ["_CompileStub_.m", "input.params", "link.params"]
            )
        }
    }

    func test_ordinaryBuildClearsStalePreviewResponseWithoutInput() throws {
        let ordinaryModes: [[String: String]] = [
            [:],
            ["ENABLE_XOJIT_PREVIEWS": "YES"],
            ["BAZEL_NATIVE_PREVIEWS": "NO", "ENABLE_XOJIT_PREVIEWS": "YES"],
            ["ENABLE_PREVIEWS": "NO"],
            ["BAZEL_NATIVE_PREVIEWS": "NO"],
            ["ENABLE_PREVIEWS": "NO", "BAZEL_NATIVE_PREVIEWS": "NO"],
        ]
        for previewSettings in ordinaryModes {
            for hasCompileStub in [false, true] {
                let directory = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                defer { try? FileManager.default.removeItem(at: directory) }

                let output = directory.appendingPathComponent("link.params")
                try "stale Preview dependency\n".write(
                    to: output,
                    atomically: true,
                    encoding: .utf8
                )
                XCTAssertEqual(
                    try runScript(
                        directory: directory,
                        previewSettings: previewSettings,
                        hasCompileStub: hasCompileStub
                    ),
                    0
                )
                XCTAssertEqual(try String(contentsOf: output), "")
                XCTAssertEqual(
                    try FileManager.default.contentsOfDirectory(
                        atPath: directory.path
                    ).sorted(),
                    hasCompileStub
                        ? ["_CompileStub_.m", "link.params"]
                        : ["link.params"]
                )
            }
        }
    }

    private func runScript(
        directory: URL,
        previewSettings: [String: String],
        hasCompileStub: Bool
    ) throws -> Int32 {
        let object = Generator.CreateCreateLinkDependenciesBuildPhaseObject
            .defaultCallable(
                subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"),
                hasCompileStub: hasCompileStub
            )
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: Data(object.content.utf8),
                format: nil
            ) as? [String: Any]
        )
        let script = try XCTUnwrap(plist["shellScript"] as? String)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script]
        process.environment = [
            "PATH": "/usr/bin:/bin",
            "PROJECT_DIR": "/source root",
            "SCRIPT_INPUT_FILE_0": directory
                .appendingPathComponent("input.params").path,
            "SCRIPT_OUTPUT_FILE_0": directory
                .appendingPathComponent("link.params").path,
            "SCRIPT_OUTPUT_FILE_1": directory
                .appendingPathComponent("_CompileStub_.m").path,
        ].merging(previewSettings) { _, value in value }
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}

// swiftlint:enable line_length
