import XcodeProj
import XCTest

@testable import generator

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
            XCTFail("Expected PreconditionError.")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo.LaunchActionInfo` should have a launchable `XCSchemeInfo.TargetInfo` value.
""")
    }
}

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
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        XCTAssertNotEqual(launchActionInfo.targetInfo.hostResolution, .unresolved)
    }
}

extension XCSchemeInfoLaunchActionInfoTests {
    func test_runnable_whenIsWidgetKitExtension() throws {
        let launchActionInfo = try XCSchemeInfo.LaunchActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfo: widgetKitExtTargetInfo
        )
        let runnable = launchActionInfo.runnable
        guard let remoteRunnable = runnable as? XCScheme.RemoteRunnable else {
            XCTFail("Expected a RemoteRunnable.")
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
            XCTFail("Expected a BuildableProductRunnable.")
            return
        }
        XCTAssertEqual(buildableProductRunnable.buildableReference, appTargetInfo.buildableReference)
    }
}

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

extension XCSchemeInfoLaunchActionInfoTests {
    func test_macroExpansion_hasHostAndIsNotWatchApp() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: unitTestTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        guard let macroExpansion = try launchActionInfo.macroExpansion else {
            XCTFail("Expected a macroExpansion.")
            return
        }
        XCTAssertEqual(macroExpansion, appHostInfo.buildableReference)
    }

    func test_macroExpansion_hasHostAndIsWatchApp() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: watchAppTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        XCTAssertNil(try launchActionInfo.macroExpansion)
    }

    func test_macroExpansion_noHostIsTestable() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: unitTestNoHostTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        guard let macroExpansion = try launchActionInfo.macroExpansion else {
            XCTFail("Expected a macroExpansion.")
            return
        }
        XCTAssertEqual(macroExpansion, unitTestNoHostTargetInfo.buildableReference)
    }

    func test_macroExpansion_noHostIsNotTestable() throws {
        let actionInfo = try XCSchemeInfo.LaunchActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let launchActionInfo = actionInfo else {
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        XCTAssertNil(try launchActionInfo.macroExpansion)
    }
}

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
            XCTFail("Expected a LaunchActionInfo.")
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
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        XCTAssertEqual(launchActionInfo.launcher, XCSchemeConstants.posixSpawnLauncher)
    }
}

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
            XCTFail("Expected a LaunchActionInfo.")
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
            XCTFail("Expected a LaunchActionInfo.")
            return
        }
        XCTAssertEqual(launchActionInfo.debugger, "")
    }
}

class XCSchemeInfoLaunchActionInfoTests: XCTestCase {
    let buildConfigurationName = "Foo"

    lazy var filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var pbxTargetsDict: [ConsolidatedTarget.Key: PBXTarget] =
        Fixtures.pbxTargets(
            in: Fixtures.pbxProj(),
            consolidatedTargets: Fixtures.consolidatedTargets
        )
        .0

    lazy var libraryTarget = pbxTargetsDict["A 1"]!
    lazy var appTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestTarget = pbxTargetsDict["B 2"]!
    lazy var widgetKitExtTarget = pbxTargetsDict["WDKE"]!
    lazy var watchAppTarget = pbxTargetsDict["W"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )
    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [appHostInfo],
        extensionPointIdentifiers: []
    )
    lazy var unitTestNoHostTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var watchAppTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: watchAppTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [appHostInfo],
        extensionPointIdentifiers: []
    )

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        index: 0
    )
}
