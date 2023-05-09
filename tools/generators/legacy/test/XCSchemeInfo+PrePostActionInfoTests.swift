import CustomDump
import XcodeProj
import XCTest

@testable import generator

// MARK: XCSchemeInfoPrePostActionInfoTests

final class XCSchemeInfoPrePostActionInfoTests: XCTestCase {
    let runnerLabel = BazelLabel("//foo")

    lazy var xcodeScheme = try! XcodeScheme(
        name: "My Scheme",
        // swiftlint:disable:next force_try
        buildAction: try! .init(targets: [
            .init(label: targetResolver.targets["A 2"]!.label),
            .init(label: targetResolver.targets["W"]!.label),
        ]),
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )

    lazy var buildConfigurationName = targetResolver.targets["A 2"]!
            .xcodeConfigurations.first!

    let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTargetInfo: targetResolver.pbxTargetInfos["A 2"]!,
            hostInfos: []
        ),
        topLevelTargetInfos: []
    )
    lazy var pbxTargetsDict = targetResolver.pbxTargets

    lazy var libraryPlatform = Fixtures.targets["A 2"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 2"]!

    lazy var unresolvedLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    // We must retain in order to retain some sub-objects (like
    // `XCConfigurationList`)
    private let pbxProj = Fixtures.pbxProj()

    lazy var targetResolver = Fixtures.targetResolver(
        pbxProj: pbxProj,
        directories: directories,
        referencedContainer: directories.containerReference
    )

    lazy var anotherAppPBXTarget = pbxTargetsDict["I"]!

    lazy var anotherAppPlatform = Fixtures.targets["I"]!.platform

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: anotherAppPBXTarget,
        platforms: [anotherAppPlatform],
        referencedContainer: directories.containerReference,
        index: 0
    )
}

// MARK: Execution Action Tests

extension XCSchemeInfoPrePostActionInfoTests {
    func test_executionAction_withoutTargetInfo() {
        // given
        let script = "script text"
        let name = "Run Script"
        let prePostActionInfo = XCSchemeInfo.PrePostActionInfo(
            name: "Run Script",
            expandVariablesBasedOn: .none,
            script: script
        )

        // when
        let executionAction = prePostActionInfo.executionAction

        // then
        XCTAssertEqual(executionAction.title, name)
        XCTAssertNil(executionAction.environmentBuildable)
        XCTAssertEqual(executionAction.scriptText, script)
    }

    func test_executionAction_withTargetInfo() {
        // given
        let script = "script text"
        let name = "Run Script"
        let prePostActionInfo = XCSchemeInfo.PrePostActionInfo(
            name: "Run Script",
            expandVariablesBasedOn: appTargetInfo,
            script: script
        )

        // when
        let executionAction = prePostActionInfo.executionAction

        // then
        XCTAssertEqual(executionAction.title, name)
        XCTAssertEqual(
            executionAction.environmentBuildable,
            appTargetInfo.buildableReference
        )
        XCTAssertEqual(executionAction.scriptText, script)
    }
}

// MARK: Custom Init Tests

extension XCSchemeInfoPrePostActionInfoTests {
    func test_customInit_noActionTargetInfo() throws {
        // given
        let prePostAction = XcodeScheme.PrePostAction(
            name: "Run Script",
            expandVariablesBasedOn: .none,
            script: "script text"
        )

        // when
        let prePostActionInfo = try XCSchemeInfo.PrePostActionInfo(
            prePostAction: prePostAction,
            buildConfigurationName: buildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: [:],
            context: "Building PrePostAction Info"
        )

        // then
        let expected = XCSchemeInfo.PrePostActionInfo(
            name: "Run Script",
            expandVariablesBasedOn: .none,
            script: "script text"
        )
        XCTAssertEqual(prePostActionInfo, expected)
    }

    func test_customInit_validActionTargetInfo() throws {
        // given
        let targetBazelLabel = BazelLabel("@//some/package:A")
        let prePostAction = XcodeScheme.PrePostAction(
            name: "Run Script",
            expandVariablesBasedOn: targetBazelLabel,
            script: "script text"
        )

        // when
        let prePostActionInfo = try XCSchemeInfo.PrePostActionInfo(
            prePostAction: prePostAction,
            buildConfigurationName: buildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["A 2"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            ),
            context: "building `PrePostActionInfo`"
        )

        // then
        let expectedTargetInfo = unresolvedLibraryTargetInfo
        let expectedActionInfo = XCSchemeInfo.PrePostActionInfo(
            name: "Run Script",
            expandVariablesBasedOn: expectedTargetInfo,
            script: "script text"
        )
        XCTAssertEqual(prePostActionInfo, expectedActionInfo)
    }

    func test_customInit_invalidActionTargetInfo() throws {
        // given
        let targetBazelLabel = BazelLabel("//some/randompackage:A")
        let prePostAction = XcodeScheme.PrePostAction(
            name: "Run Script",
            expandVariablesBasedOn: targetBazelLabel,
            script: "script text"
        )

        // when
        let prePostActionInfo = {
            try XCSchemeInfo.PrePostActionInfo(
                prePostAction: prePostAction,
                buildConfigurationName: self.buildConfigurationName,
                targetResolver: self.targetResolver,
                targetIDsByLabelAndConfiguration: self.xcodeScheme.resolveTargetIDs(
                    targetResolver: self.targetResolver,
                    xcodeConfigurations: self.targetResolver.targets["A 2"]!
                        .xcodeConfigurations,
                    runnerLabel: self.runnerLabel
                ),
                context: "building `PrePostActionInfo`"
            )
        }

        // then
        XCTAssertThrowsError(try prePostActionInfo())
    }
}

// MARK: Host Resolution Tests

extension XCSchemeInfoPrePostActionInfoTests {
    func test_resolveHosts_noActionTargetInfo() throws {
        // given
        let prePostAction = XcodeScheme.PrePostAction(
            name: "Run Script",
            expandVariablesBasedOn: .none,
            script: "script text"
        )
        let prePostActionInfo = try XCSchemeInfo.PrePostActionInfo(
            prePostAction: prePostAction,
            buildConfigurationName: buildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["A 2"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            ),
            context: "building `PrePostActionInfo`"
        )

        // when
        let resolvedPrePostActionInfos = try [prePostActionInfo]
            .resolveHosts(topLevelTargetInfos: [])

        // then
        XCTAssertNoDifference(resolvedPrePostActionInfos, [prePostActionInfo])
    }

    func test_resolveHosts_validActionTargetInfo_withTopLevelTargetInfos() throws {
        // given
        let targetBazelLabel = BazelLabel("@//some/package:W")
        let prePostAction = XcodeScheme.PrePostAction(
            name: "Run Script",
            expandVariablesBasedOn: targetBazelLabel,
            script: "script text"
        )
        let prePostActionInfo = try XCSchemeInfo.PrePostActionInfo(
            prePostAction: prePostAction,
            buildConfigurationName: buildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["A 2"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            ),
            context: "building `PrePostActionInfo`"
        )
        let topLevelTargetInfos: [XCSchemeInfo.TargetInfo] = [
            .init(
                pbxTarget: anotherAppPBXTarget,
                platforms: [anotherAppPlatform],
                referencedContainer: directories.containerReference,
                hostInfos: [appHostInfo],
                extensionPointIdentifiers: []
            ),
        ]

        // when
        let resolvedPrePostActionInfos = try [prePostActionInfo].resolveHosts(
            topLevelTargetInfos: topLevelTargetInfos
        )

        // then
        let expectedTargetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: pbxTargetsDict["W"]!,
            platforms: [Fixtures.targets["W"]!.platform],
            referencedContainer: directories.containerReference,
            hostInfos: [appHostInfo],
            extensionPointIdentifiers: []
        )
        let resolvedVariableExpansion = XCSchemeInfo.TargetInfo(
            resolveHostFor: expectedTargetInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
        let expectedActionInfo = XCSchemeInfo.PrePostActionInfo(
            name: "Run Script",
            expandVariablesBasedOn: resolvedVariableExpansion,
            script: "script text"
        )
        XCTAssertNoDifference(resolvedPrePostActionInfos, [expectedActionInfo])
    }

    func test_resolveHosts_validActionTargetInfo_withoutHostInfos_withoutTopLevelTargetInfos() throws {
        // given
        let targetBazelLabel = BazelLabel("@//some/package:A")
        let prePostAction = XcodeScheme.PrePostAction(
            name: "Run Script",
            expandVariablesBasedOn: targetBazelLabel,
            script: "script text"
        )
        let prePostActionInfo = try XCSchemeInfo.PrePostActionInfo(
            prePostAction: prePostAction,
            buildConfigurationName: buildConfigurationName,
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeConfigurations: targetResolver.targets["A 2"]!
                    .xcodeConfigurations,
                runnerLabel: runnerLabel
            ),
            context: "building `PrePostActionInfo`"
        )

        // when
        let resolvedPrePostActionInfos = try [prePostActionInfo].resolveHosts(
            topLevelTargetInfos: []
        )

        // then
        resolvedPrePostActionInfos.forEach { actionInfo in
            XCTAssertEqual(
                actionInfo.expandVariablesBasedOn?.hostResolution,
                XCSchemeInfo.HostResolution.none
            )
        }
    }
}
