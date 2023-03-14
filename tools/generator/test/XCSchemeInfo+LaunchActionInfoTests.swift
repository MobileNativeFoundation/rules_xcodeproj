import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_init_withLaunchableTarget() throws {
        let args = ["args"]
        let env = ["RELEASE_KRAKEN": "true"]
        let workingDirectory = "/path/to/working/dir"
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: appTargetInfo,
            args: args,
            env: env,
            workingDirectory: workingDirectory
        )
        XCTAssertEqual(launchActionInfo.buildConfigurationName, buildConfigurationName)
        XCTAssertEqual(launchActionInfo.targetInfo, appTargetInfo)
        XCTAssertEqual(launchActionInfo.args, args)
        XCTAssertEqual(launchActionInfo.env, env)
        XCTAssertEqual(launchActionInfo.workingDirectory, workingDirectory)
    }

    func test_init_withoutLaunchableTarget() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: libraryTargetInfo
        )) {
          thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected `PreconditionError`")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo.LaunchActionInfo` should have a launchable `XCSchemeInfo.TargetInfo` value.
""")
    }
}

// MARK: - Host Resolution Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_hostResolution_withoutLaunchActionInfo() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: nil,
            topLevelTargetInfos: []
        )
        XCTAssertNil(actionInfo)
    }

    func test_hostResolution_withLaunchActionInfo() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }
        XCTAssertNotEqual(launchActionInfo.targetInfo.hostResolution, .unresolved)
    }
}

// MARK: - `runnable` Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_runnable_whenIsWidgetKitExtension() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: widgetKitExtTargetInfo
        )
        let runnable = launchActionInfo.runnable
        guard let remoteRunnable = runnable as? XCScheme.RemoteRunnable else {
            XCTFail("Expected a `RemoteRunnable`")
            return
        }
        XCTAssertEqual(remoteRunnable.buildableReference, widgetKitExtTargetInfo.buildableReference)
    }

    func test_runnable_whenIsNotWidgetKitExtension() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: appTargetInfo
        )
        let runnable = launchActionInfo.runnable
        guard let buildableProductRunnable = runnable as? XCScheme.BuildableProductRunnable else {
            XCTFail("Expected a `BuildableProductRunnable`")
            return
        }
        XCTAssertEqual(buildableProductRunnable.buildableReference, appTargetInfo.buildableReference)
    }
}

// MARK: `askForAppToLaunch` Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_askForAppToLaunch_whenIsWidgetKitExtension() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: widgetKitExtTargetInfo
        )
        XCTAssertTrue(launchActionInfo.askForAppToLaunch)
    }

    func test_askForAppToLaunch_whenIsNotWidgetKitExtension() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: appTargetInfo
        )
        XCTAssertFalse(launchActionInfo.askForAppToLaunch)
    }
}

// MARK: - `macroExpansion` Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_macroExpansion() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: unitTestTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }
        guard let macroExpansion = try launchActionInfo.macroExpansion else {
            XCTFail("Expected a `macroExpansion`")
            return
        }
        XCTAssertEqual(macroExpansion, appHostInfo.buildableReference)
    }
}

// MARK: - `launcher` Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_launcher_canUseDebugLauncher() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }
        XCTAssertEqual(launchActionInfo.launcher, XCScheme.defaultLauncher)
    }

    func test_launcher_cannotUseDebugLauncher() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: widgetKitExtTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }
        XCTAssertEqual(launchActionInfo.launcher, XCSchemeConstants.posixSpawnLauncher)
    }
}

// MARK: - `debugger` Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_debugger_canUseDebugLauncher() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }
        XCTAssertEqual(launchActionInfo.debugger, XCScheme.defaultDebugger)
    }

    func test_debugger_cannotUseDebugLauncher() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: widgetKitExtTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a `LaunchActionInfo`")
            return
        }
        XCTAssertEqual(launchActionInfo.debugger, "")
    }
}

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoLaunchActionInfoTests {
    func test_customSchemeInit_noLaunchAction() throws {
        let actual = try XCSchemeInfo.LaunchActionInfo(
            launchAction: nil,
            defaultBuildConfigurationName: "Random",
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: [:]
        )
        XCTAssertNil(actual)
    }

    func test_customSchemeInit_withLaunchAction() throws {
        let actual = try XCSchemeInfo.LaunchActionInfo(
            launchAction: xcodeScheme.launchAction,
            defaultBuildConfigurationName: appPBXTarget
                .defaultBuildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["A 2"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            )
        )
        let expectedTargetInfo = try targetResolver.targetInfo(targetID: "A 2")
        let expected = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: expectedTargetInfo.pbxTarget
                .defaultBuildConfigurationName,
            targetInfo: expectedTargetInfo,
            args: customArgs,
            env: customEnv,
            workingDirectory: customWorkingDirectory
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoLaunchActionInfoTests: XCTestCase {
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
    lazy var appPlatform = Fixtures.targets["A 2"]!.platform
    lazy var unitTestPlatform = Fixtures.targets["B 2"]!.platform
    lazy var widgetKitExtPlatform = Fixtures.targets["WDKE"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var appPBXTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!
    lazy var widgetKitExtPBXTarget = pbxTargetsDict["WDKE"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
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
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtPBXTarget,
        platforms: [widgetKitExtPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )
    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestPBXTarget,
        platforms: [unitTestPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [appHostInfo],
        extensionPointIdentifiers: []
    )

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: directories.containerReference,
        index: 0
    )

    let customArgs = ["custom_args"]
    let customEnv = ["RELEASE_KRAKEN": "TRUE"]
    let customWorkingDirectory = "/path/to/work"

    // swiftlint:disable:next force_try
    lazy var xcodeScheme = try! XcodeScheme(
        name: "My Scheme",
        launchAction: .init(
            target: targetResolver.targets["A 2"]!.label,
            args: customArgs,
            env: customEnv,
            workingDirectory: customWorkingDirectory
        )
    )
}
