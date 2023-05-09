import CustomDump
import XcodeProj
import XCTest

@testable import generator

// MARK: - XCScheme.BuildableReference Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildableReference_init() throws {
        let buildableReference = XCScheme.BuildableReference(
            pbxTarget: libraryPBXTarget,
            referencedContainer: directories.containerReference
        )
        let expected = XCScheme.BuildableReference(
            referencedContainer: directories.containerReference,
            blueprint: libraryPBXTarget,
            buildableName: libraryPBXTarget.buildableName,
            blueprintName: libraryPBXTarget.name
        )
        XCTAssertNoDifference(buildableReference, expected)
    }
}

// MARK: - XCScheme.BuildAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildAction_init_buildModeBazel() throws {
        let buildAction = try XCScheme.BuildAction(buildActionInfo: buildActionInfo)
        let expected = try XCScheme.BuildAction(
            buildActionEntries: buildActionInfo.targets.buildActionEntries,
            preActions: buildActionInfo.targets.map(\.targetInfo).buildPreActions(),
            parallelizeBuild: true,
            buildImplicitDependencies: false
        )
        XCTAssertNoDifference(buildAction, expected)
    }

    func test_BuildAction_init_preActions_postActions() throws {
        // given
        let preActions = [
            prePostActionInfoWithNoTargetInfo,
            prePostActionInfoWithTargetInfo,
        ]
        let postActions = [
            prePostActionInfoWithNoTargetInfo,
            prePostActionInfoWithTargetInfo,
        ]
        // swiftlint:disable:next force_try
        let buildActionInfo = try! XCSchemeInfo.BuildActionInfo(
            resolveHostsFor: .init(
                targets: [libraryTargetInfo, anotherLibraryTargetInfo].map {
                    .init(targetInfo: $0, buildFor: .allEnabled)
                },
                preActions: preActions,
                postActions: postActions
            ),
            topLevelTargetInfos: []
        )!

        // when
        let buildAction = try XCScheme.BuildAction(buildActionInfo: buildActionInfo)

        // then
        let expected = try XCScheme.BuildAction(
            buildActionEntries: buildActionInfo.targets.buildActionEntries,
            preActions: preActions.map(\.executionAction) +
                buildActionInfo.targets.map(\.targetInfo).buildPreActions(),
            postActions: postActions.map(\.executionAction),
            parallelizeBuild: true,
            buildImplicitDependencies: false
        )
        XCTAssertNoDifference(buildAction, expected)
    }

    func test_BuildAction_init_buildModeXcode() throws {
        let buildAction = try XCScheme.BuildAction(buildActionInfo: buildActionInfo)
        let expected = try XCScheme.BuildAction(
            buildActionEntries: buildActionInfo.targets.buildActionEntries,
            preActions: buildActionInfo.targets.map(\.targetInfo).buildPreActions(),
            parallelizeBuild: true,
            buildImplicitDependencies: false
        )
        XCTAssertNoDifference(buildAction, expected)
    }
}

// MARK: - XCScheme.BuildAction.Entry Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildAction_Entry_init() throws {
        let entry = XCScheme.BuildAction.Entry(
            buildableReference: libraryTargetInfo.buildableReference,
            buildFor: .default
        )
        let expected = XCScheme.BuildAction.Entry(
            buildableReference: libraryTargetInfo.buildableReference,
            buildFor: [
                .running,
                .testing,
                .profiling,
                .archiving,
                .analyzing,
            ]
        )
        XCTAssertNoDifference(entry, expected)
    }
}

// MARK: XCScheme.TestAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_TestAction_init_noCustomEnvArgs_launchActionHasRunnable_xcode() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                preActions: [.init(name: "Custom Pre Script", expandVariablesBasedOn: nil, script: "exit 0")],
                postActions: [.init(name: "Custom Post Script", expandVariablesBasedOn: libraryTargetInfo, script: "exit 1")]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .xcode,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: true
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            preActions: [
                .init(scriptText: "exit 0", title: "Custom Pre Script", environmentBuildable: nil),
            ],
            postActions: [
                .init(scriptText: "exit 1", title: "Custom Post Script", environmentBuildable: libraryTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: true
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_noCustomEnvArgs_noLaunchActionHasRunnable_xcode() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                preActions: [.init(name: "Custom Pre Script", expandVariablesBasedOn: nil, script: "exit 0")],
                postActions: [.init(name: "Custom Post Script", expandVariablesBasedOn: libraryTargetInfo, script: "exit 1")]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .xcode,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: false
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            preActions: [
                .init(scriptText: "exit 0", title: "Custom Pre Script", environmentBuildable: nil),
            ],
            postActions: [
                .init(scriptText: "exit 1", title: "Custom Post Script", environmentBuildable: libraryTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: false
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_withCustomEnvArgs_launchActionHasRunnable_xcode() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                args: ["--hello"],
                env: ["CUSTOM_ENV_VAR": "goodbye"]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .xcode,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: true
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: false,
            commandlineArguments: .init(arguments: [.init(name: "--hello", enabled: true)]),
            environmentVariables: [
                .init(variable: "CUSTOM_ENV_VAR", value: "goodbye", enabled: true),
            ]
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_withCustomEnvArgs_noLaunchActionHasRunnable_xcode() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                args: ["--hello"],
                env: ["CUSTOM_ENV_VAR": "goodbye"]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .xcode,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: false
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: false,
            commandlineArguments: .init(arguments: [.init(name: "--hello", enabled: true)]),
            environmentVariables: [
                .init(variable: "CUSTOM_ENV_VAR", value: "goodbye", enabled: true),
            ]
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_noCustomEnvArgs_launchActionHasRunnable_bazel() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .bazel,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: true
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: true,
            environmentVariables: nil
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_noCustomEnvArgs_noLaunchActionHasRunnable_bazel() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .bazel,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: false
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: false,
            environmentVariables: .bazelLaunchEnvironmentVariables
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_withCustomEnvArgs_launchActionHasRunnable_bazel() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                args: ["--hello"],
                env: ["CUSTOM_ENV_VAR": "goodbye"]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .bazel,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: true
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: false,
            commandlineArguments: .init(arguments: [.init(name: "--hello", enabled: true)]),
            environmentVariables: (
                [.init(variable: "CUSTOM_ENV_VAR", value: "goodbye", enabled: true)] +
                    .bazelLaunchEnvironmentVariables
            ).sortedLocalizedStandard()
        )
        XCTAssertNoDifference(actual, expected)
    }

    func test_TestAction_init_withCustomEnvArgs_noLaunchActionHasRunnable_bazel() throws {
        let buildConfigurationName = "Foo"
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                args: ["--hello"],
                env: ["CUSTOM_ENV_VAR": "goodbye"]
            ),
            topLevelTargetInfos: []
        ).orThrow()
        let actual = try XCScheme.TestAction(
            buildMode: .bazel,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: false
        )
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            shouldUseLaunchSchemeArgsEnv: false,
            commandlineArguments: .init(arguments: [.init(name: "--hello", enabled: true)]),
            environmentVariables: (
                [.init(variable: "CUSTOM_ENV_VAR", value: "goodbye", enabled: true)] +
                    .bazelLaunchEnvironmentVariables
            ).sortedLocalizedStandard()
        )
        XCTAssertNoDifference(actual, expected)
    }
}

// MARK: XCScheme.LaunchAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_LaunchAction_init_noCustomEnvArgsWorkingDir_xcode() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = launchActionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }

        let productType = launchActionInfo.targetInfo.productType
        let launchAction = try XCScheme.LaunchAction(
            buildMode: .xcode,
            launchActionInfo: launchActionInfo,
            otherPreActions: []
        )
        let expected = try XCScheme.LaunchAction(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: nil,
            environmentVariables: nil,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(launchAction, expected)
    }

    func test_LaunchAction_init_noCustomEnvArgsWorkingDir_bazel() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = launchActionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }

        let productType = launchActionInfo.targetInfo.productType
        let launchAction = try XCScheme.LaunchAction(
            buildMode: .bazel,
            launchActionInfo: launchActionInfo,
            otherPreActions: []
        )
        let expected = try XCScheme.LaunchAction(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: nil,
            environmentVariables: .bazelLaunchEnvironmentVariables,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(launchAction, expected)
    }

    func test_LaunchAction_init_customEnvArgsWorkingDir_bazel() throws {
        let args = ["--hello"]
        let env = ["CUSTOM_ENV_VAR": "goodbye"]
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo,
                args: args,
                env: env
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = launchActionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }

        let productType = launchActionInfo.targetInfo.productType
        let launchAction = try XCScheme.LaunchAction(
            buildMode: .bazel,
            launchActionInfo: launchActionInfo,
            otherPreActions: []
        )
        let expected = try XCScheme.LaunchAction(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: nil,
            commandlineArguments: .init(arguments: [.init(name: args[0], enabled: true)]),
            environmentVariables: (
                [.init(variable: "CUSTOM_ENV_VAR", value: env["CUSTOM_ENV_VAR"]!, enabled: true)] +
                    .bazelLaunchEnvironmentVariables
            ).sortedLocalizedStandard(),
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(launchAction, expected)
    }
}

// MARK: XCScheme.ProfileAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_ProfileAction_init_noCustomEnvArgsWorkingDir_xcode() throws {
        let profileActionInfo = XCSchemeInfo.ProfileActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let profileActionInfo = profileActionInfo else {
            XCTFail("Expected a `ProfileActionInfo`")
            return
        }

        let productType = profileActionInfo.targetInfo.productType
        let profileAction = try XCScheme.ProfileAction(
            buildMode: .xcode,
            profileActionInfo: profileActionInfo,
            otherPreActions: []
        )
        let expected = try XCScheme.ProfileAction(
            runnable: profileActionInfo.runnable,
            buildConfiguration: profileActionInfo.buildConfigurationName,
            macroExpansion: profileActionInfo.macroExpansion,
            askForAppToLaunch: nil,
            environmentVariables: nil,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(profileAction, expected)
    }

    func test_ProfileAction_init_noCustomEnvArgsWorkingDir_bazel() throws {
        let profileActionInfo = XCSchemeInfo.ProfileActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let profileActionInfo = profileActionInfo else {
            XCTFail("Expected a `ProfileActionInfo`")
            return
        }

        let productType = profileActionInfo.targetInfo.productType
        let profileAction = try XCScheme.ProfileAction(
            buildMode: .bazel,
            profileActionInfo: profileActionInfo,
            otherPreActions: []
        )
        let expected = try XCScheme.ProfileAction(
            runnable: profileActionInfo.runnable,
            buildConfiguration: profileActionInfo.buildConfigurationName,
            macroExpansion: profileActionInfo.macroExpansion,
            askForAppToLaunch: nil,
            environmentVariables: nil,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(profileAction, expected)
    }

    func test_ProfileAction_init_customEnvArgsWorkingDir_bazel() throws {
        let args = ["--hello"]
        let env = ["CUSTOM_ENV_VAR": "goodbye"]
        let profileActionInfo = XCSchemeInfo.ProfileActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo,
                args: args,
                env: env
            ),
            topLevelTargetInfos: []
        )
        guard let profileActionInfo = profileActionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }

        let productType = profileActionInfo.targetInfo.productType
        let profileAction = try XCScheme.ProfileAction(
            buildMode: .bazel,
            profileActionInfo: profileActionInfo,
            otherPreActions: []
        )
        let expected = try XCScheme.ProfileAction(
            runnable: profileActionInfo.runnable,
            buildConfiguration: profileActionInfo.buildConfigurationName,
            macroExpansion: profileActionInfo.macroExpansion,
            shouldUseLaunchSchemeArgsEnv: false,
            askForAppToLaunch: nil,
            commandlineArguments: .init(arguments: [.init(name: args[0], enabled: true)]),
            environmentVariables: (
                [.init(variable: "CUSTOM_ENV_VAR", value: env["CUSTOM_ENV_VAR"]!, enabled: true)] +
                    .bazelLaunchEnvironmentVariables
            ).sortedLocalizedStandard(),
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(profileAction, expected)
    }
}

// MARK: - XCScheme.ExecutionAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_ExecutionAction_withNativeTarget_noHostIndex_bazelBuildMode() throws {
        let action = XCScheme.ExecutionAction(
            buildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: nil
        )
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertNoDifference(
            action.environmentBuildable,
            libraryTargetInfo.buildableReference
        )
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertFalse(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_"))
    }

    func test_ExecutionAction_withNativeTarget_withHostIndex_bazelBuildMode() throws {
        let hostIndex = 7
        let action = XCScheme.ExecutionAction(
            buildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: hostIndex
        )
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertNoDifference(
            action.environmentBuildable,
            libraryTargetInfo.buildableReference
        )
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertTrue(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_\(hostIndex)"))
    }

    func test_ExecutionAction_withNativeTarget_noHostIndex_xcodeBuildMode() throws {
        let action = XCScheme.ExecutionAction(
            buildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: nil
        )
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertFalse(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_"))
    }

    func test_ExecutionAction_withNativeTarget_withHostIndex_xcodeBuildMode() throws {
        let hostIndex = 7
        let action = XCScheme.ExecutionAction(
            buildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: hostIndex
        )
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertNoDifference(
            action.environmentBuildable,
            libraryTargetInfo.buildableReference
        )
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertTrue(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_\(hostIndex)"))
    }
}

extension XCSchemeExtensionsTests {
    func test_BuildableReference_Sequence_inStableOrder() throws {
        let buildRefA = XCScheme.BuildableReference(
            referencedContainer: "refContainer",
            blueprintIdentifier: nil,
            buildableName: "a",
            blueprintName: "a"
        )
        let buildRefB = XCScheme.BuildableReference(
            referencedContainer: "refContainer",
            blueprintIdentifier: nil,
            buildableName: "b",
            blueprintName: "b"
        )
        let buildableReferences = [buildRefB, buildRefA]
        XCTAssertNoDifference(
            buildableReferences.inStableOrder,
            [buildRefA, buildRefB]
        )
    }
}

// MARK: - Test Data

class XCSchemeExtensionsTests: XCTestCase {
    let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )

    lazy var pbxTargetsDict: [ConsolidatedTarget.Key: PBXNativeTarget] =
        Fixtures.pbxTargets(
            in: Fixtures.pbxProj(),
            directories: directories,
            consolidatedTargets: Fixtures.consolidatedTargets
        )
        .0

    lazy var libraryPlatform = Fixtures.targets["A 1"]!.platform
    lazy var anotherLibraryPlatform = Fixtures.targets["C 1"]!.platform
    lazy var appPlatform = Fixtures.targets["A 2"]!.platform
    lazy var unitTestPlatform = Fixtures.targets["B 2"]!.platform
    lazy var uiTestPlatform = Fixtures.targets["B 3"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var anotherLibraryPBXTarget = pbxTargetsDict["C 1"]!
    lazy var appPBXTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!
    lazy var uiTestPBXTarget = pbxTargetsDict["B 3"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var anotherLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: anotherLibraryPBXTarget,
        platforms: [anotherLibraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
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
    lazy var uiTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: uiTestPBXTarget,
        platforms: [uiTestPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var prePostActionInfoWithNoTargetInfo = XCSchemeInfo.PrePostActionInfo(
        name: "Run Script",
        expandVariablesBasedOn: .none,
        script: "script text"
    )
    lazy var prePostActionInfoWithTargetInfo = XCSchemeInfo.PrePostActionInfo(
        name: "Run Script",
        expandVariablesBasedOn: libraryTargetInfo,
        script: "script text"
    )
    // swiftlint:disable:next force_try
    lazy var buildActionInfo = try! XCSchemeInfo.BuildActionInfo(
        resolveHostsFor: .init(
            targets: [libraryTargetInfo, anotherLibraryTargetInfo].map {
                .init(targetInfo: $0, buildFor: .allEnabled)
            }
        ),
        topLevelTargetInfos: []
    ).orThrow()
}

// MARK: XCScheme.LaunchAction Diagnostics Tests

extension XCSchemeExtensionsTests {
    func test_LaunchAction_init_diagnostics() throws {
        // given
        let sanitizers = XCSchemeInfo.DiagnosticsInfo.Sanitizers(
            address: true,
            thread: false,
            undefinedBehavior: true
        )
        let diagnostics = XCSchemeInfo.DiagnosticsInfo(
            sanitizers: sanitizers
        )
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfo: appTargetInfo,
                args: [],
                diagnostics: diagnostics,
                env: [:]
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = launchActionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }

        let productType = launchActionInfo.targetInfo.productType

        // when
        let launchAction = try XCScheme.LaunchAction(
            buildMode: .xcode,
            launchActionInfo: launchActionInfo,
            otherPreActions: []
        )

        // then
        let expected = try XCScheme.LaunchAction(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: nil,
            enableAddressSanitizer: true,
            enableThreadSanitizer: false,
            enableUBSanitizer: true,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle
        )
        XCTAssertNoDifference(launchAction, expected)
    }
}

// MARK: XCScheme.TestAction Diagnostics Tests

extension XCSchemeExtensionsTests {
    func test_TestAction_init_diagnostics() throws {
        // given
        let buildConfigurationName = "Foo"
        let sanitizers = XCSchemeInfo.DiagnosticsInfo.Sanitizers(
            address: true,
            thread: false,
            undefinedBehavior: true
        )
        let diagnostics = XCSchemeInfo.DiagnosticsInfo(
            sanitizers: sanitizers
        )
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: "Foo",
                targetInfos: [unitTestTargetInfo, uiTestTargetInfo],
                diagnostics: diagnostics
            ),
            topLevelTargetInfos: []
        )
        guard let testActionInfo = testActionInfo else {
            XCTFail("Expected a `TestActionInfo`")
            return
        }

        // when
        let testAction = try XCScheme.TestAction(
            buildMode: .xcode,
            testActionInfo: testActionInfo,
            launchActionHasRunnable: true
        )

        // then
        let expected = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: unitTestTargetInfo.buildableReference,
            testables: [
                .init(skipped: false, buildableReference: unitTestTargetInfo.buildableReference),
                .init(skipped: false, buildableReference: uiTestTargetInfo.buildableReference),
            ],
            enableAddressSanitizer: true,
            enableThreadSanitizer: false,
            enableUBSanitizer: true
        )
        XCTAssertNoDifference(testAction, expected)
    }
}
