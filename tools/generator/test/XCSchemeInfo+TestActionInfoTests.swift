import CustomDump
import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTestActionInfoTests {
    func test_init_withEmptyTargetInfos() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfos: []
        )) {
          thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected `PreconditionError`")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo.TestActionInfo` should have at least one \
`XCSchemeInfo.TargetInfo`.
""")
    }

    func test_init_withNoTestables() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfos: [libraryTargetInfo]
        )) {
          thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected `PreconditionError`")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo.TestActionInfo` should only contain testable \
`XCSchemeInfo.TargetInfo` values.
""")
    }

    func test_init_allIsWell() throws {
        let args = ["--hello"]
        let env = ["CUSTOM_ENV_VAR": "goodbye"]
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfos: [unitTestTargetInfo],
            args: args,
            env: env
        )
        XCTAssertEqual(
            testActionInfo.buildConfigurationName,
            buildConfigurationName
        )
        XCTAssertEqual(testActionInfo.targetInfos, [unitTestTargetInfo])
        XCTAssertEqual(testActionInfo.args, args)
        XCTAssertEqual(testActionInfo.env, env)
    }
}

// MARK: - Host Resolution Tests

extension XCSchemeInfoTestActionInfoTests {
    func test_hostResolution() throws {
        let actionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo]
            ),
            topLevelTargetInfos: []
        )
        guard let testActionInfo = actionInfo else {
            XCTFail("Expected a `TestActionInfo`")
            return
        }
        XCTAssertEqual(
            testActionInfo.buildConfigurationName,
            buildConfigurationName
        )
        for targetInfo in testActionInfo.targetInfos {
            XCTAssertNotEqual(targetInfo.hostResolution, .unresolved)
        }
    }
}

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoTestActionInfoTests {
    func test_customSchemeInit_noTestAction() throws {
        let actual = try XCSchemeInfo.TestActionInfo(
            testAction: nil,
            defaultBuildConfigurationName: "Random",
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: [:],
            args: [:],
            envs: [:]
        )
        XCTAssertNil(actual)
    }

    func test_customSchemeInit_withTestAction() throws {
        let actual = try XCSchemeInfo.TestActionInfo(
            testAction: xcodeScheme.testAction,
            defaultBuildConfigurationName: unitTestPBXTarget
                .defaultBuildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["B 2"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            ),
            args: [:],
            envs: [:]
        ).orThrow("Expected a `TestActionInfo`")
        let testTargetInfo = try targetResolver.targetInfo(targetID: "B 2")
        let expected = try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: testTargetInfo.pbxTarget
                .defaultBuildConfigurationName,
            targetInfos: [testTargetInfo],
            expandVariablesBasedOn: testTargetInfo
        )
        XCTAssertNoDifference(actual, expected)
    }
}

// MARK: `macroExpansion` Tests

extension XCSchemeInfoTestActionInfoTests {
    func test_macroExpansion() throws {
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo]
            ),
            topLevelTargetInfos: []
        ).orThrow("Expected `testActionInfo`")
        let macroExpansion = try testActionInfo.macroExpansion
            .orThrow("Expected `macroExpansion`")
        XCTAssertNoDifference(
            macroExpansion,
            unitTestTargetInfo.buildableReference
        )
    }
}

// MARK: - Test Data

class XCSchemeInfoTestActionInfoTests: XCTestCase {
    let buildConfigurationName = "Foo"

    let runnerLabel = BazelLabel("//foo")

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

    lazy var pbxTargetsDict = targetResolver.pbxTargets

    lazy var libraryPlatform = Fixtures.targets["A 1"]!.platform
    lazy var unitTestPlatform = Fixtures.targets["B 2"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestPBXTarget,
        platforms: [unitTestPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    // swiftlint:disable:next force_try
    lazy var xcodeScheme = try! XcodeScheme(
        name: "My Scheme",
        // swiftlint:disable:next force_try
        testAction: try! .init(targets: [targetResolver.targets["B 2"]!.label])
    )
}
