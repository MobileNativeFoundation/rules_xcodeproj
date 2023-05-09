import XcodeProj
import XCTest

@testable import generator

// MARK: - Host Resolution Tests

extension XCSchemeInfoBuildActionInfoTests {
    func test_hostResolution_noBuildActionInfo() throws {
        let actionInfo = try XCSchemeInfo.BuildActionInfo(
            resolveHostsFor: nil,
            topLevelTargetInfos: topLevelTargetInfos
        )
        XCTAssertNil(actionInfo)
    }

    func test_hostResolution_withBuildActionInfo() throws {
        let actionInfo = try XCSchemeInfo.BuildActionInfo(
            resolveHostsFor: .init(
                targets: [unresolvedLibraryTargetInfoWithHosts].map {
                    .init(targetInfo: $0, buildFor: .allEnabled)
                }
            ),
            topLevelTargetInfos: topLevelTargetInfos
        )
        guard let buildActionInfo = actionInfo else {
            XCTFail("Expected a `BuildActionInfo`")
            return
        }
        // We could check for the host resolution not equal to .unresolved. However, by checking for
        // a specific selected host, we are sure that the topLevelTargetInfos was passed along
        // correctly.
        guard let targetInfo = buildActionInfo.targets.first?.targetInfo else {
            XCTFail("Expected a `TargetInfo`")
            return
        }
        let selectedHostInfo = try targetInfo.selectedHostInfo
        XCTAssertEqual(selectedHostInfo, unitTestHostInfo)
    }
}

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoBuildActionInfoTests {
    func test_customSchemeInit_withBuildAction() throws {
        // To keep this test simple, we are passing in the pre-defaults version of `BuildAction`.
        // Hence, the "A 2" target from the scheme will not appear in the `BuildAction`.
        let actual = try XCSchemeInfo.BuildActionInfo(
            buildAction: xcodeScheme.buildAction,
            buildConfigurationName: buildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["A 1"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            )
        )
        let expected = try XCSchemeInfo.BuildActionInfo(
            targets: [
                try .init(
                    targetInfo: targetResolver.targetInfo(targetID: "A 1"),
                    buildFor: .allEnabled
                ),
            ]
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoBuildActionInfoTests: XCTestCase {
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

    lazy var buildConfigurationName = targetResolver.targets["A 1"]!
            .xcodeConfigurations.first!

    lazy var pbxTargetsDict = targetResolver.pbxTargets

    lazy var libraryPlatform = Fixtures.targets["A 1"]!.platform
    lazy var appPlatform = Fixtures.targets["A 2"]!.platform
    lazy var unitTestPlatform = Fixtures.targets["B 2"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var appPBXTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: directories.containerReference,
        index: 0
    )
    lazy var unitTestHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: unitTestPBXTarget,
        platforms: [unitTestPlatform],
        referencedContainer: directories.containerReference,
        index: 1
    )

    lazy var unresolvedLibraryTargetInfoWithHosts = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [appHostInfo, unitTestHostInfo],
        extensionPointIdentifiers: []
    )

    lazy var applicationTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    lazy var topLevelTargetInfos: [XCSchemeInfo.TargetInfo] = [
        .init(
            pbxTarget: unitTestPBXTarget,
            platforms: [unitTestPlatform],
            referencedContainer: directories.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
    ]

    lazy var xcodeScheme = try! XcodeScheme(
        name: "My Scheme",
        // swiftlint:disable:next force_try
        buildAction: try! .init(targets: [.init(label: targetResolver.targets["A 1"]!.label)]),
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}

// MARK: - Launchable Targets Tests

extension XCSchemeInfoBuildActionInfoTests {
    func test_launchableTargets_actionInfoForLibTargets() throws {
        // given
        let actionInfo = try XCSchemeInfo.BuildActionInfo(
            resolveHostsFor: .init(
                targets: [unresolvedLibraryTargetInfoWithHosts].map {
                    .init(targetInfo: $0, buildFor: .allEnabled)
                }
            ),
            topLevelTargetInfos: topLevelTargetInfos
        )
        guard let buildActionInfo = actionInfo else {
            XCTFail("Expected a `BuildActionInfo`")
            return
        }

        // when
        let launchableTargets = buildActionInfo.launchableTargets

        // then
        XCTAssertEqual(launchableTargets, [])
    }

    func test_launchableTargets_actionInfoForAppTargets() throws {
        // given
        let actionInfo = try XCSchemeInfo.BuildActionInfo(
            resolveHostsFor: .init(
                targets: [
                    applicationTargetInfo,
                    unresolvedLibraryTargetInfoWithHosts,
                ].map {
                    .init(targetInfo: $0, buildFor: .allEnabled)
                }
            ),
            topLevelTargetInfos: topLevelTargetInfos
        )
        guard let buildActionInfo = actionInfo else {
            XCTFail("Expected a `BuildActionInfo`")
            return
        }

        let resolvedTargetInfo = try XCSchemeInfo.TargetInfo(
            resolveHostFor: targetResolver.targetInfo(targetID: "A 2"),
            topLevelTargetInfos: []
        )

        let buildTargetInfos = [resolvedTargetInfo]
            .map { XCSchemeInfo.BuildTargetInfo(targetInfo: $0, buildFor: .allEnabled) }

        // when
        let launchableTargets = Array(buildActionInfo.launchableTargets)

        // then
        XCTAssertEqual(launchableTargets, buildTargetInfos)
    }
}
