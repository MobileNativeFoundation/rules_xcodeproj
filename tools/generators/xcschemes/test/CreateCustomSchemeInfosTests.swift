import Foundation
import PBXProj
import XCScheme
import XCTest

@testable import xcschemes

final class CreateCustomSchemeInfosTests: XCTestCase {
    // MARK: - defaultCallable

    func test_defaultCallable_parsesCustomSchemeInfo() async throws {
        let parsed = try await createCustomSchemeInfos()

        XCTAssertEqual(
            parsed.schemeInfos,
            [
                .mock(
                    name: "Scheme",
                    test: .mock(
                        buildTargets: [parsed.testBuildTarget],
                        commandLineArguments: [
                            .init(
                                value: "--test-target",
                                isEnabled: false,
                                isLiteralString: true
                            ),
                        ],
                        enableAddressSanitizer: true,
                        enableThreadSanitizer: false,
                        enableUBSanitizer: true,
                        enableMainThreadChecker: false,
                        enableThreadPerformanceChecker: true,
                        environmentVariables: .defaultEnvironmentVariables + [
                            .init(key: "TEST_ENV", value: "2", isEnabled: false),
                        ],
                        options: .init(
                            appLanguage: "en",
                            appRegion: "US",
                            codeCoverage: true
                        ),
                        testTargets: [
                            .init(target: parsed.testTarget, isEnabled: true),
                        ],
                        useRunArgsAndEnv: false,
                        xcodeConfiguration: "TestCfg"
                    ),
                    run: .mock(
                        buildTargets: [parsed.runBuildTarget],
                        commandLineArguments: [
                            .init(
                                value: "--run-target",
                                isEnabled: true,
                                isLiteralString: true
                            ),
                        ],
                        customWorkingDirectory: "/tmp/run",
                        enableMainThreadChecker: true,
                        enableThreadPerformanceChecker: false,
                        enableAddressSanitizer: false,
                        enableThreadSanitizer: true,
                        enableUBSanitizer: false,
                        environmentVariables: .defaultEnvironmentVariables + [
                            .init(key: "RUN_ENV", value: "1", isEnabled: true),
                        ],
                        launchTarget: .target(
                            primary: parsed.runTarget,
                            extensionHost: parsed.extensionHost
                        ),
                        runBuildPostActionsOnFailure: false,
                        storeKitConfiguration: parsed.expectedStoreKitConfiguration,
                        xcodeConfiguration: "RunCfg"
                    ),
                    profile: .mock(
                        commandLineArguments: [
                            .init(
                                value: "profiling\narg",
                                isEnabled: true,
                                isLiteralString: true
                            ),
                        ],
                        customWorkingDirectory: "/tmp/profile",
                        environmentVariables: [
                            .init(
                                key: "PROFILE_KEY",
                                value: "profile\nvalue",
                                isEnabled: true
                            ),
                        ],
                        launchTarget: .path("/tmp/Profile.app"),
                        useRunArgsAndEnv: false,
                        xcodeConfiguration: "ProfileCfg"
                    ),
                    executionActions: [
                        .init(
                            title: "Build Start\nTitle",
                            scriptText: "echo build\nstart",
                            action: .build,
                            isPreAction: true,
                            target: parsed.runTarget,
                            order: -10
                        ),
                        .init(
                            title: "Run End",
                            scriptText: "echo run end",
                            action: .run,
                            isPreAction: false,
                            target: parsed.runTarget,
                            order: 10
                        ),
                        .init(
                            title: "Test Start",
                            scriptText: "echo test start",
                            action: .test,
                            isPreAction: true,
                            target: parsed.testTarget,
                            order: nil
                        ),
                        .init(
                            title: "Profile End",
                            scriptText: "echo profile end",
                            action: .profile,
                            isPreAction: false,
                            target: parsed.runTarget,
                            order: 20
                        ),
                    ]
                ),
            ]
        )
    }

    func test_defaultCallable_parsesRunBuildPostActionsOnFailure() async throws {
        let parsed = try await createCustomSchemeInfos(
            runBuildPostActionsOnFailure: true
        )

        XCTAssertEqual(
            parsed.schemeInfos.map(\.run.runBuildPostActionsOnFailure),
            [true]
        )
    }

    // MARK: - mergingEnvironmentVariables

    func test_merging_environment_variables() throws {
        let targets: [SchemeInfo.TestTarget] = [
            .init(
                target: .init(
                    key: .init([.init("target1")]),
                    productType: .unitTestBundle,
                    buildableReference: .init(
                        blueprintIdentifier: "",
                        buildableName: "",
                        blueprintName: "",
                        referencedContainer: "",
                    )
                ),
                isEnabled: true
            ),
            .init(
                target: .init(
                    key: .init([.init("target2")]),
                    productType: .unitTestBundle,
                    buildableReference: .init(
                        blueprintIdentifier: "",
                        buildableName: "",
                        blueprintName: "",
                        referencedContainer: "",
                    )
                ),
                isEnabled: true
            ),
        ]

        // No environment variables
        try XCTAssert(mergingEnvironmentVariables([:], in: []).isEmpty)

        // Environment variables with no overlap
        try XCTAssertEqual(
            mergingEnvironmentVariables(
                [
                    "target1": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                    "target2": [EnvironmentVariable(key: "VAR2", value: "value2", isEnabled: true)],
                ],
                in: targets
            ),
            [
                EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true),
                EnvironmentVariable(key: "VAR2", value: "value2", isEnabled: true),
            ]
        )

        // Environment variables with overlap (target1 and target2 both have VAR1, and the output should contain VAR1 because the values match.
        try XCTAssertEqual(
            mergingEnvironmentVariables(
                [
                    "target1": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                    "target2": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                ],
                in: targets
            ),
            [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)]
        )

        // Environment variables with overlap but different values (target1 and target2 both have VAR1, but the values differ, so the output should be empty because there is no consistent value for VAR1).
        try XCTAssertThrowsError(
            mergingEnvironmentVariables(
                [
                    "target1": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                    "target2": [EnvironmentVariable(key: "VAR1", value: "value2", isEnabled: true)],
                ],
                in: targets
            )
        )
    }

    // MARK: - URL.relativize

    func test_url_relativize() {
        typealias TestCase = (dest: URL, source: URL, expected: String?)
        let testCases: [TestCase] = [
            // Common root
            (URL(filePath: "/path/to/my/file.txt"), URL(filePath: "/path/to/your/dir"), "../my/file.txt"),
            // No common root
            (URL(filePath: "/path/to/my/file.txt"), URL(filePath: "/home/from/your/dir"), "../../../path/to/my/file.txt"),
            // Both empty paths (implied to be /private/tmp in Bazel)
            (URL(filePath: ""), URL(filePath: ""), "/private/tmp"),
            // Empty destination path, absolute source path
            (URL(filePath: ""), URL(filePath: "/path"), "private/tmp"),
            // Absolute destination path, empty source path
            (URL(filePath: "/path"), URL(filePath: ""), "../path"),
            // Relative destination path (implied to be relative to /private/tmp in Bazel), absolute source path
            (URL(filePath: "path/to/file.txt"), URL(filePath: "/path/to/dir"), "../../private/tmp/path/to/file.txt"),
            // Absolute destination path, relative source path
            (URL(filePath: "/path/to/file.txt"), URL(filePath: "path/to/dir"), "../../../../path/to/file.txt"),
            // Weird relative destination path
            (URL(filePath: "../../file.txt"), URL(filePath: "/path/to/dir"), "../../file.txt"),
            // Absolute destination path, weird relative source path
            (URL(filePath: "/path/to/file.txt"), URL(filePath: "../../to/dir"), "../path/to/file.txt"),
        ]
        for (dest, source, expected) in testCases {
            let actual = dest.relativize(from: source)
            XCTAssertEqual(expected, actual)
        }
    }
}

private struct ParsedCustomSchemeInfos {
    let expectedStoreKitConfiguration: String?
    let schemeInfos: [SchemeInfo]
    let extensionHost: Target
    let runBuildTarget: Target
    let runTarget: Target
    let testBuildTarget: Target
    let testTarget: Target
}

private func createCustomSchemeInfos(
    runBuildPostActionsOnFailure: Bool = false
) async throws -> ParsedCustomSchemeInfos {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    let schemesDirectory = directory.appendingPathComponent(
        "Project.xcodeproj/xcshareddata/xcschemes",
        isDirectory: true
    )
    try FileManager.default.createDirectory(
        at: schemesDirectory,
        withIntermediateDirectories: true
    )

    let runTarget = makeTarget(
        "run_extension",
        productType: .appExtension
    )
    let extensionHost = makeTarget(
        "host_app",
        productType: .application
    )
    let runBuildTarget = makeTarget("run_build_target")
    let testBuildTarget = makeTarget("test_build_target")
    let testTarget = makeTarget(
        "test_target",
        productType: .unitTestBundle
    )
    let targetsByID = Dictionary(
        uniqueKeysWithValues: [
            runTarget,
            extensionHost,
            runBuildTarget,
            testBuildTarget,
            testTarget,
        ].map { ($0.key.sortedIds.first!, $0) }
    )

    let customSchemesFile = directory.appendingPathComponent(
        "custom_schemes_file"
    )
    try writeLines([
        "1",
        "Scheme",
        "1",
        "test_target",
        "1",
        "test_build_target",
        "",
        "-1",
        "-1",
        "1",
        "0",
        "1",
        "0",
        "1",
        "0",
        "1",
        "en",
        "US",
        "1",
        "TestCfg",
        "run_build_target",
        "",
        "-1",
        "-1",
        "1",
        "0",
        "1",
        "0",
        "1",
        "0",
        "Configs/Fixture.storekit",
        "RunCfg",
        "0",
        "run_extension",
        "host_app",
        "/tmp/run",
        runBuildPostActionsOnFailure ? "1" : "0",
        "",
        "1",
        "profiling\0arg",
        "1",
        "1",
        "1",
        "PROFILE_KEY",
        "profile\0value",
        "1",
        "0",
        "0",
        "ProfileCfg",
        "1",
        "/tmp/Profile.app",
        "/tmp/profile",
    ], to: customSchemesFile)

    let executionActionsFile = directory.appendingPathComponent(
        "execution_actions_file"
    )
    try writeLines([
        "Scheme",
        "build",
        "1",
        "Build Start\0Title",
        "echo build\0start",
        "run_extension",
        "-10",
        "Scheme",
        "run",
        "0",
        "Run End",
        "echo run end",
        "run_extension",
        "10",
        "Scheme",
        "test",
        "1",
        "Test Start",
        "echo test start",
        "test_target",
        "",
        "Scheme",
        "profile",
        "0",
        "Profile End",
        "echo profile end",
        "run_extension",
        "20",
    ], to: executionActionsFile)

    let expectedStoreKitConfiguration = URL(
        filePath: "Configs/Fixture.storekit",
        relativeTo: directory
    ).relativize(from: schemesDirectory)

    let schemeInfos = try await Generator.CreateCustomSchemeInfos
        .defaultCallable(
            commandLineArguments: [
                runTarget.key.sortedIds.first!: [
                    .init(
                        value: "--run-target",
                        isEnabled: true,
                        isLiteralString: true
                    ),
                ],
                testTarget.key.sortedIds.first!: [
                    .init(
                        value: "--test-target",
                        isEnabled: false,
                        isLiteralString: true
                    ),
                ],
            ],
            customSchemesFile: customSchemesFile,
            environmentVariables: [
                runTarget.key.sortedIds.first!: [
                    .init(key: "RUN_ENV", value: "1", isEnabled: true),
                ],
                testTarget.key.sortedIds.first!: [
                    .init(key: "TEST_ENV", value: "2", isEnabled: false),
                ],
            ],
            executionActionsFile: executionActionsFile,
            extensionHostIDs: [
                runTarget.key.sortedIds.first!: [
                    extensionHost.key.sortedIds.first!,
                ],
            ],
            schemesDirectory: schemesDirectory,
            targetsByID: targetsByID,
            workspace: directory
        )

    return ParsedCustomSchemeInfos(
        expectedStoreKitConfiguration: expectedStoreKitConfiguration,
        schemeInfos: schemeInfos,
        extensionHost: extensionHost,
        runBuildTarget: runBuildTarget,
        runTarget: runTarget,
        testBuildTarget: testBuildTarget,
        testTarget: testTarget
    )
}

private func makeTarget(
    _ id: String,
    productType: PBXProductType = .staticLibrary
) -> Target {
    let targetID = TargetID(id)
    return Target(
        key: .init([targetID]),
        productType: productType,
        buildableReference: .init(
            blueprintIdentifier: "\(id)_blueprintIdentifier",
            buildableName: "\(id)_buildableName",
            blueprintName: id,
            referencedContainer: "container:/tmp/\(id).xcodeproj"
        )
    )
}

private func writeLines(
    _ lines: [String],
    to url: URL
) throws {
    try (lines.joined(separator: "\n") + "\n").write(
        to: url,
        atomically: true,
        encoding: .utf8
    )
}
