import XCTest
@testable import generator

// MARK: `BuildAction.init` Tests

extension XcodeSchemeTests {
    func test_BuildAction_init_noDuplicateLabels() throws {
        let buildTarget = try XcodeScheme.BuildAction(
            targets: [.init(label: "@//foo"), .init(label: "@//bar")]
        )
        XCTAssertEqual(buildTarget.targets.count, 2)
    }

    func test_BuildAction_init_withDuplicateLabels() throws {
        try assertPreconditionError(
            XcodeScheme.BuildAction(
                targets: [.init(label: "@//foo"), .init(label: "@//foo")]
            ),
            expectedMessage: """
Found a duplicate label @//foo:foo in provided `XcodeScheme.BuildTarget` values.
"""
        )
    }

    func test_BuildAction_init_noTargets() throws {
        try assertPreconditionError(
            XcodeScheme.BuildAction(targets: []),
            expectedMessage: """
No `XcodeScheme.BuildTarget` values were provided to `XcodeScheme.BuildAction`.
"""
        )
    }
}

// MARK: `TestAction.init` Tests

extension XcodeSchemeTests {
    func test_TestAction_init_noTargets() throws {
        try assertPreconditionError(
            XcodeScheme.TestAction(targets: []),
            expectedMessage: """
No `BazelLabel` values were provided to `XcodeScheme.TestAction`.
"""
        )
    }

    func test_TestAction_init_withTargets() throws {
        let actual = try XcodeScheme.TestAction(
            targets: [unitTestLabel, uiTestLabel]
        )
        XCTAssertEqual(actual.targets, [unitTestLabel, uiTestLabel])
        XCTAssertNil(actual.args)
        XCTAssertNil(actual.env)
    }

    func test_TestAction_init_withTargets_withCustomValues() throws {
        let args = ["--hello"]
        let env = ["CUSTOM_ENV_VAR": "goodbye"]
        let actual = try XcodeScheme.TestAction(
            targets: [unitTestLabel, uiTestLabel],
            args: args,
            env: env
        )
        XCTAssertEqual(actual.targets, [unitTestLabel, uiTestLabel])
        XCTAssertEqual(actual.args, args)
        XCTAssertEqual(actual.env, env)
    }
}

// MARK: `XcodeScheme.init` Tests

extension XcodeSchemeTests {
    func test_XcodeScheme_init_noActions() throws {
        try assertPreconditionError(
            XcodeScheme(name: "Foo"),
            expectedMessage: """
No actions were provided for the scheme "Foo".
"""
        )
    }
}

// MARK: `XcodeScheme.withDefaults` Tests

extension XcodeSchemeTests {
    func test_XcodeScheme_withDefaults_noBuild_withLaunch_noProfile() throws {
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            launchAction: .init(target: macOSAppLabel)
        )
        let actual = try xcodeScheme.withDefaults
        let expected = try XcodeScheme(
            name: schemeName,
            buildAction: .init(
                targets: [
                    .init(
                        label: macOSAppLabel,
                        buildFor: .init(
                            running: .enabled,
                            profiling: .enabled,
                            archiving: .enabled,
                            analyzing: .enabled
                        )
                    ),
                ]
            ),
            launchAction: .init(target: macOSAppLabel),
            profileAction: .init(target: macOSAppLabel)
        )
        XCTAssertEqual(actual, expected)
    }

    func test_XcodeScheme_withDefaults_noBuild_withLaunch_withProfile() throws {
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            launchAction: .init(target: macOSAppLabel),
            profileAction: .init(target: iOSAppLabel)
        )
        let actual = try xcodeScheme.withDefaults
        let expected = try XcodeScheme(
            name: schemeName,
            buildAction: .init(
                targets: [
                    .init(
                        label: macOSAppLabel,
                        buildFor: .init(
                            running: .enabled,
                            archiving: .enabled,
                            analyzing: .enabled
                        )
                    ),
                    .init(
                        label: iOSAppLabel,
                        buildFor: .init(
                            profiling: .enabled,
                            analyzing: .enabled
                        )
                    ),
                ]
            ),
            launchAction: .init(target: macOSAppLabel),
            profileAction: .init(target: iOSAppLabel)
        )
        XCTAssertEqual(actual, expected)
    }

    func test_XcodeScheme_withDefaults_withBuild_withLaunch_noProfile_profilingEnabled() throws {
        // Ensure that we respect manually specified profiling setting
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                // Purposefully not using .allEnabled as it is a default.
                .init(label: macOSAppLabel, buildFor: .init(
                    running: .enabled, profiling: .enabled, archiving: .enabled
                )),
            ]),
            launchAction: .init(target: macOSAppLabel)
        )
        let actual = try xcodeScheme.withDefaults
        let expected = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(
                    label: macOSAppLabel,
                    buildFor: .init(
                        running: .enabled,
                        profiling: .enabled,
                        archiving: .enabled,
                        analyzing: .enabled
                    )
                ),
            ]),
            launchAction: .init(target: macOSAppLabel),
            profileAction: .init(target: macOSAppLabel)
        )
        XCTAssertEqual(actual, expected)
    }

    func test_XcodeScheme_withDefaults_withBuild_withLaunch_noProfile_profilingDisabled() throws {
        // Ensure that we respect manually specified profiling setting
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(label: macOSAppLabel, buildFor: .init(
                    running: .enabled, profiling: .disabled
                )),
            ]),
            launchAction: .init(target: macOSAppLabel)
        )
        let actual = try xcodeScheme.withDefaults
        let expected = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(label: macOSAppLabel, buildFor: .init(
                    running: .enabled,
                    profiling: .disabled,
                    archiving: .enabled,
                    analyzing: .enabled
                )),
            ]),
            launchAction: .init(target: macOSAppLabel)
        )
        XCTAssertEqual(actual, expected)
    }

    func test_XcodeScheme_withDefaults_withBuild_withLaunch_runningDisabled() throws {
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(
                    label: macOSAppLabel,
                    buildFor: .init(running: .disabled)
                ),
            ]),
            launchAction: .init(target: macOSAppLabel)
        )
        try assertUsageError(
            xcodeScheme.withDefaults,
            expectedMessage: """
The `build_for` value, "running", for "\(macOSAppLabel)" in the \
"\(schemeName)" Xcode scheme was disabled, but the target is referenced in the \
scheme's launch action.
"""
        )
    }

    func test_XcodeScheme_withDefaults_withBuild_withProifle_profilingDisabled() throws {
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(
                    label: macOSAppLabel,
                    buildFor: .init(profiling: .disabled)
                ),
            ]),
            profileAction: .init(target: macOSAppLabel)
        )
        try assertUsageError(
            xcodeScheme.withDefaults,
            expectedMessage: """
The `build_for` value, "profiling", for "\(macOSAppLabel)" in the \
"\(schemeName)" Xcode scheme was disabled, but the target is referenced in the \
scheme's profile action.
"""
        )
    }

    func test_XcodeScheme_withDefaults_withBuild_withTest_testingDisabled() throws {
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(
                    label: unitTestLabel,
                    buildFor: .init(testing: .disabled)
                ),
            ]),
            testAction: .init(targets: [unitTestLabel])
        )
        try assertUsageError(
            xcodeScheme.withDefaults,
            expectedMessage: """
The `build_for` value, "testing", for "\(unitTestLabel)" in the \
"\(schemeName)" Xcode scheme was disabled, but the target is referenced in the \
scheme's test action.
"""
        )
    }

    func test_XcodeScheme_withDefaults_noTargetsWithRunningEnabled() throws {
        let xcodeScheme = try XcodeScheme(
            name: schemeName,
            testAction: .init(targets: [unitTestLabel, uiTestLabel])
        )
        let actual = try xcodeScheme.withDefaults
        let expected = try XcodeScheme(
            name: schemeName,
            buildAction: .init(targets: [
                .init(
                    label: unitTestLabel,
                    buildFor: .init(
                        running: .enabled,
                        testing: .enabled,
                        archiving: .enabled,
                        analyzing: .enabled
                    )
                ),
                .init(
                    label: uiTestLabel,
                    buildFor: .init(
                        running: .enabled,
                        testing: .enabled,
                        archiving: .enabled,
                        analyzing: .enabled
                    )
                ),
            ]),
            testAction: .init(targets: [unitTestLabel, uiTestLabel])
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: Assertions

extension XcodeSchemeTests {
    func assertUsageError<T>(
        _ closure: @autoclosure () throws -> T,
        expectedMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var thrown: Error?
        XCTAssertThrowsError(try closure(), file: file, line: line) {
            thrown = $0
        }
        guard let usageError = thrown as? UsageError else {
            XCTFail(
                "Expected `UsageError`, but was \(String(describing: thrown)).",
                file: file,
                line: line
            )
            return
        }
        XCTAssertEqual(
            usageError.message,
            expectedMessage,
            file: file,
            line: line
        )
    }

    func assertPreconditionError<T>(
        _ closure: @autoclosure () throws -> T,
        expectedMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var thrown: Error?
        XCTAssertThrowsError(try closure(), file: file, line: line) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail(
                """
Expected `PreconditionError`, but was \(String(describing: thrown)).
""",
                file: file,
                line: line
            )
            return
        }
        XCTAssertEqual(
            preconditionError.message, expectedMessage,
            file: file,
            line: line
        )
    }
}

// MARK: `BuildAction.init` Tests

class XcodeSchemeTests: XCTestCase {
    let schemeName = "Foo"

    let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )

    // We must retain in order to retain some sub-objects (like
    // `XCConfigurationList`)
    private let pbxProj = Fixtures.pbxProj()

    lazy var targetResolver = Fixtures.targetResolver(
        pbxProj: pbxProj,
        directories: directories,
        referencedContainer: directories.containerReference
    )

    lazy var macOSAppLabel = targetResolver.targets["A 2"]!.label
    lazy var iOSAppLabel = targetResolver.targets["AC"]!.label
    lazy var unitTestLabel = targetResolver.targets["B 2"]!.label
    lazy var uiTestLabel = targetResolver.targets["B 3"]!.label
}
