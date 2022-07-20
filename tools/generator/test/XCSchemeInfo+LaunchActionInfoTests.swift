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
        XCTFail("IMPLEMENT ME!")
    }

    func test_hostResolution_withLaunchActionInfo() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoLaunchActionInfoTests {
    func test_runnable_whenIsWidgetKitExtension() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_runnable_whenIsNotWidgetKitExtension() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoLaunchActionInfoTests {
    func test_askForAppToLaunch() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoLaunchActionInfoTests {
    func test_macroExpansion_hasHostAndIsNotWatchApp() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_macroExpansion_hasHostAndIsWatchApp() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_macroExpansion_noHostIsTestable() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_macroExpansion_noHostIsNotTestable() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoLaunchActionInfoTests {
    func test_launcher_canUseDebugLauncher() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_launcher_cannotUseDebugLauncher() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoLaunchActionInfoTests {
    func test_debugger_canUseDebugLauncher() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_debugger_cannotUseDebugLauncher() throws {
        XCTFail("IMPLEMENT ME!")
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
}
