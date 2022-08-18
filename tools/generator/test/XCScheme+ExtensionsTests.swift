import XcodeProj
import XCTest

@testable import generator

// MARK: - XCScheme.BuildableReference Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildableReference_init() throws {
        let buildableReference = XCScheme.BuildableReference(
            pbxTarget: libraryPBXTarget,
            referencedContainer: filePathResolver.containerReference
        )
        let expected = XCScheme.BuildableReference(
            referencedContainer: filePathResolver.containerReference,
            blueprint: libraryPBXTarget,
            buildableName: libraryPBXTarget.buildableName,
            blueprintName: libraryPBXTarget.name
        )
        XCTAssertEqual(buildableReference, expected)
    }
}

// MARK: - XCScheme.BuildAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildAction_init_buildModeBazel() throws {
        let buildAction = try XCScheme.BuildAction(buildActionInfo: buildActionInfo)
        let expected = XCScheme.BuildAction(
            buildActionEntries: try buildActionInfo.targets.buildActionEntries,
            preActions: try buildActionInfo.targets.map(\.targetInfo).buildPreActions(),
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
    }

    func test_BuildAction_init_buildModeXcode() throws {
        let buildAction = try XCScheme.BuildAction(buildActionInfo: buildActionInfo)
        let expected = XCScheme.BuildAction(
            buildActionEntries: try buildActionInfo.targets.buildActionEntries,
            preActions: try buildActionInfo.targets.map(\.targetInfo).buildPreActions(),
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
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
        XCTAssertEqual(entry, expected)
    }
}

// MARK: XCScheme.LaunchAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_LaunchAction_init_noCustomEnvArgsWorkingDir() throws {
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
            launchActionInfo: launchActionInfo
        )
        let expected = XCScheme.LaunchAction(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: try launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: nil,
            environmentVariables: .bazelLaunchVariables,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle,
            customLLDBInitFile: XCSchemeConstants.customLLDBInitFile
        )
        XCTAssertEqual(launchAction, expected)
    }

    func test_LaunchAction_init_customEnvArgsWorkingDir() throws {
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
            launchActionInfo: launchActionInfo
        )
        let expected = XCScheme.LaunchAction(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: try launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: nil,
            commandlineArguments: .init(arguments: [.init(name: args[0], enabled: true)]),
            environmentVariables: [
                .init(variable: "CUSTOM_ENV_VAR", value: env["CUSTOM_ENV_VAR"]!, enabled: true),
            ] + .bazelLaunchVariables,
            launchAutomaticallySubstyle: productType.launchAutomaticallySubstyle,
            customLLDBInitFile: XCSchemeConstants.customLLDBInitFile
        )
        XCTAssertEqual(launchAction, expected)
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
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
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
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
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
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
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
        XCTAssertEqual(buildableReferences.inStableOrder, [buildRefA, buildRefB])
    }
}

// MARK: - Test Data

class XCSchemeExtensionsTests: XCTestCase {
    lazy var filePathResolver = FilePathResolver(
        workspaceDirectory: "/Users/TimApple/app",
        externalDirectory: "/some/bazel3/external",
        bazelOutDirectory: "/some/bazel3/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var pbxTargetsDict: [ConsolidatedTarget.Key: PBXTarget] =
        Fixtures.pbxTargets(
            in: Fixtures.pbxProj(),
            consolidatedTargets: Fixtures.consolidatedTargets
        )
        .0

    lazy var libraryPlatform = Fixtures.targets["A 1"]!.platform
    lazy var anotherLibraryPlatform = Fixtures.targets["C 1"]!.platform
    lazy var appPlatform = Fixtures.targets["A 2"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var anotherLibraryPBXTarget = pbxTargetsDict["C 1"]!
    lazy var appPBXTarget = pbxTargetsDict["A 2"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var anotherLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: anotherLibraryPBXTarget,
        platforms: [anotherLibraryPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    // swiftlint:disable:next force_try
    lazy var buildActionInfo = try! XCSchemeInfo.BuildActionInfo(
        resolveHostsFor: .init(
            targets: [libraryTargetInfo, anotherLibraryTargetInfo].map {
                .init(targetInfo: $0, buildFor: .allEnabled)
            }
        ),
        topLevelTargetInfos: []
    )!
}
