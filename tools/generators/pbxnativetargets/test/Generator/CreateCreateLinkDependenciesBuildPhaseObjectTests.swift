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

    func test_nativeStaticRuntimeStagingUsesSelectedEnvironmentAndLiteralPolicy() throws {
        let directory = try runtimeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("link.params")
        let flags = "[\"-fprofile-generate=Author's profile dir\",\"-nodefaultlibs\"]"
        try flags.write(to: directory.appendingPathComponent("policy.json"), atomically: true, encoding: .utf8)
        XCTAssertEqual(try runScript(directory: directory, previewSettings: runtimeEnvironment(directory), hasCompileStub: true, isStaticLibrary: true), 0)
        XCTAssertEqual(try String(contentsOf: output), "-L/source root/libraries\n\"/selected runtime.a\"\n")
        let received = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("received.json"))) as? [String: Any])
        XCTAssertEqual(received["args"] as? [String], [
            "--driver", "/selected toolchain/usr/bin/clang", "--sdk", "/selected SDK.sdk",
            "--target", "arm64-apple-ios16.0-simulator", "--swift-profile", "YES",
            "--driver-policy-file", directory.appendingPathComponent("policy.json").path,
        ])
        XCTAssertEqual(received["policy"] as? [String], ["-fprofile-generate=Author's profile dir", "-nodefaultlibs"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("_CompileStub_.m").path))
    }

    func test_runtimePlanningFailurePreservesPriorResponse() throws {
        for overrides in [["FAIL_RUNTIME_QUERY": "YES"], ["ARCHS": "arm64 x86_64"], ["ARCHS": ""], ["LD": ""], ["SDK_DIR": ""], ["LLVM_TARGET_TRIPLE_OS_VERSION": ""]] {
            let directory = try runtimeDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let output = directory.appendingPathComponent("link.params")
            try "previous response\n".write(to: output, atomically: true, encoding: .utf8)
            let environment = runtimeEnvironment(directory).merging(overrides) { _, value in value }
            XCTAssertNotEqual(try runScript(directory: directory, previewSettings: environment, hasCompileStub: false, isStaticLibrary: true), 0, "Failed validation for \(overrides)")
            XCTAssertEqual(try String(contentsOf: output), "previous response\n")
            XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: directory.path).contains { $0.hasPrefix("link.params.tmp.") })
        }
    }

    func test_runtimeQueryIsAbsentForOrdinaryLegacyNonStaticAndIndexing() throws {
        for (isStatic, overrides, expected) in [
            (true, ["BAZEL_NATIVE_PREVIEWS": "NO", "ENABLE_PREVIEWS": "NO"], ""),
            (true, ["BAZEL_NATIVE_PREVIEWS": "NO", "ENABLE_PREVIEWS": "YES"], "-L/source root/libraries\n"),
            (false, [String: String](), "-L/source root/libraries\n"),
            (true, ["ACTION": "indexbuild"], ""),
            (true, ["ACTION": "indexbuild", "INDEX_ENABLE_BUILD_ARENA": "NO"], ""),
            (true, ["INDEX_ENABLE_BUILD_ARENA": "YES"], ""),
            (true, ["ACTION": "install"], "-L/source root/libraries\n"),
        ] {
            let directory = try runtimeDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            // No prepared policy is needed in any inactive mode.
            try FileManager.default.removeItem(at: directory.appendingPathComponent("policy.json"))
            let environment = runtimeEnvironment(directory).merging(overrides) { _, value in value }
            XCTAssertEqual(try runScript(directory: directory, previewSettings: environment, hasCompileStub: false, isStaticLibrary: isStatic), 0)
            XCTAssertEqual(try String(contentsOf: directory.appendingPathComponent("link.params")), expected)
            XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("received.json").path))
        }
    }

    func test_staticPolicyInputIsConditionalAndHelperIsDeclared() throws {
        let object = Generator.CreateCreateLinkDependenciesBuildPhaseObject.defaultCallable(
            subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"), hasCompileStub: true, isStaticLibrary: true
        )
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(object.content.utf8), format: nil) as? [String: Any])
        XCTAssertEqual(plist["inputPaths"] as? [String], [
            "$(LINK_PARAMS_FILE)", "$(LINK_PARAMS_FILE)$(BAZEL_PREVIEW_RUNTIME_POLICY_SUFFIX)",
            "$(BAZEL_INTEGRATION_DIR)/preview_runtime_link_params.py",
            "$(LD)", "$(SDK_DIR)/SDKSettings.plist",
        ])
        XCTAssertEqual(plist["outputPaths"] as? [String], ["$(DERIVED_FILE_DIR)/link.params", "$(DERIVED_FILE_DIR)/_CompileStub_.m"])
    }

    private func runtimeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("runtime's \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "-L$(PROJECT_DIR)/libraries\n".write(to: directory.appendingPathComponent("input.params"), atomically: true, encoding: .utf8)
        try "[]".write(to: directory.appendingPathComponent("policy.json"), atomically: true, encoding: .utf8)
        // Mock only the planning boundary; kernel tests execute its parser and
        // real selected-driver controls separately. No Xcode/runtime is started.
        try #"""
import json, os, sys
from pathlib import Path
root = Path(__file__).parent
if os.environ.get("FAIL_RUNTIME_QUERY") == "YES":
    sys.exit(1)
args = sys.argv[1:]
if not args[args.index("--sdk") + 1] or not args[args.index("--driver") + 1]:
    sys.exit(1)
policy = json.loads(Path(args[args.index("--driver-policy-file") + 1]).read_text())
(root / "received.json").write_text(json.dumps({"args": args, "policy": policy}))
print('"/selected runtime.a"')
"""#.write(to: directory.appendingPathComponent("preview_runtime_link_params.py"), atomically: true, encoding: .utf8)
        return directory
    }

    private func runtimeEnvironment(_ directory: URL) -> [String: String] {
        [
            "BAZEL_NATIVE_PREVIEWS": "YES", "ENABLE_PREVIEWS": "NO", "ACTION": "build",
            "BAZEL_INTEGRATION_DIR": directory.path, "SCRIPT_INPUT_FILE_1": directory.appendingPathComponent("policy.json").path,
            "ARCHS": "arm64", "LD": "/selected toolchain/usr/bin/clang", "SDK_DIR": "/selected SDK.sdk",
            "LLVM_TARGET_TRIPLE_VENDOR": "apple", "LLVM_TARGET_TRIPLE_OS_VERSION": "ios16.0", "LLVM_TARGET_TRIPLE_SUFFIX": "-simulator",
            "BAZEL_PREVIEW_SWIFT_PROFILE": "YES", "CURRENT_ARCH": "undefined_arch", "NATIVE_ARCH_ACTUAL": "arm64e",
            "TOOLCHAIN_DIR": "/misleading metal toolchain", "SDKROOT": "iphonesimulator26.5",
        ]
    }

    private func runScript(
        directory: URL,
        previewSettings: [String: String],
        hasCompileStub: Bool,
        isStaticLibrary: Bool = false
    ) throws -> Int32 {
        let object = Generator.CreateCreateLinkDependenciesBuildPhaseObject
            .defaultCallable(
                subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"),
                hasCompileStub: hasCompileStub,
                isStaticLibrary: isStaticLibrary
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
