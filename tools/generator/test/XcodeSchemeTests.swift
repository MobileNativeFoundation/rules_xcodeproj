import XCTest

@testable import generator

// MARK: `BuildAction.init` Tests

extension XcodeSchemeTests {
    func test_BuildAction_init_noDuplicateLabels() throws {
        let buildTarget = try XcodeScheme.BuildAction(
            targets: [.init(label: "//foo"), .init(label: "//bar")]
        )
        XCTAssertEqual(buildTarget.targets.count, 2)
    }

    func test_BuildAction_init_withDuplicateLabels() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try XcodeScheme.BuildAction(
                targets: [.init(label: "//foo"), .init(label: "//foo")]
            )
        ) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected `PreconditionError`.")
            return
        }
        XCTAssertEqual(preconditionError.message, """
Found a duplicate label //foo:foo in provided `XcodeScheme.BuildTarget` values.
""")
    }

    func test_BuildAction_init_noTargets() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

// MARK: `TestAction.init` Tests

extension XcodeSchemeTests {
    func test_TestAction_init_noTargets() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_TestAction_init_withTargets() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

// MARK: `XcodeScheme.init` Tests

extension XcodeSchemeTests {
    func test_XcodeScheme_init_noActions() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_XcodeScheme_init_withActions() throws {
        XCTFail("IMPLEMENT ME!")
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
            buildAction: try .init(
                targets: [
                    .init(
                        label: macOSAppLabel,
                        buildFor: .init(running: .enabled, profiling: .enabled)
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
            buildAction: try .init(
                targets: [
                    .init(
                        label: macOSAppLabel,
                        buildFor: .init(running: .enabled)
                    ),
                    .init(
                        label: iOSAppLabel,
                        buildFor: .init(profiling: .enabled)
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
            buildAction: try .init(targets: [
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
            buildAction: try .init(targets: [
                .init(label: macOSAppLabel, buildFor: .init(
                    running: .enabled, profiling: .enabled, archiving: .enabled
                )),
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
            buildAction: try .init(targets: [
                .init(label: macOSAppLabel, buildFor: .init(
                    running: .enabled, profiling: .disabled
                )),
            ]),
            launchAction: .init(target: macOSAppLabel)
        )
        let actual = try xcodeScheme.withDefaults
        let expected = try XcodeScheme(
            name: schemeName,
            buildAction: try .init(targets: [
                .init(label: macOSAppLabel, buildFor: .init(
                    running: .enabled, profiling: .disabled
                )),
            ]),
            launchAction: .init(target: macOSAppLabel)
        )
        XCTAssertEqual(actual, expected)
    }

    func test_XcodeScheme_withDefaults_withBuild_withLaunch_runningDisabled() throws {
        // // Ensure that we respect manually specified profiling setting
        // let xcodeScheme = try XcodeScheme(
        //     name: schemeName,
        //     buildAction: try .init(targets: [
        //         .init(label: macOSAppLabel, buildFor: .init(
        //             running: .enabled, profiling: .disabled, archiving: .enabled
        //         )),
        //     ]),
        //     launchAction: .init(target: macOSAppLabel)
        // )
        // var thrown: Error?
        // XCTAssertThrowsError(try xcodeScheme.withDefaults) {
        //     thrown = $0
        // }
        // guard let preconditionError = thrown as? PreconditionError else {
        //     XCTFail("Expected `PreconditionError`")
        //     return
        // }
        // XCTAssertEqual(preconditionError.message, """
// """)
        XCTFail("IMPLEMENT ME!")
    }

    func test_XcodeScheme_withDefaults_withBuild_withProifle_profilingDisabled() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_XcodeScheme_withDefaults_withBuild_withTest_testingDisabled() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

// MARK: `BuildAction.init` Tests

class XcodeSchemeTests: XCTestCase {
    let schemeName = "Foo"

    lazy var filePathResolver = FilePathResolver(
        externalDirectory: "/some/bazel9/external",
        bazelOutDirectory: "/some/bazel9/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )

    lazy var macOSAppLabel = targetResolver.targets["A 2"]!.label
    lazy var iOSAppLabel = targetResolver.targets["AC"]!.label
}
