import XcodeProj
import XCTest

@testable import generator

// MARK: - Host Resolution Tests

extension XCSchemeInfoProfileActionInfoTests {
    func test_hostResolution_withoutProfileActionInfo() throws {
        let actionInfo = XCSchemeInfo.ProfileActionInfo(
            resolveHostsFor: nil,
            topLevelTargetInfos: []
        )
        XCTAssertNil(actionInfo)
    }

    func test_hostResolution_withProfileActionInfo() throws {
        let actionInfo = XCSchemeInfo.ProfileActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let profileActionInfo = actionInfo else {
            XCTFail("Expected a `ProfileActionInfo`")
            return
        }
        XCTAssertNotEqual(profileActionInfo.targetInfo.hostResolution, .unresolved)
    }
}

// MARK: - `runnable` Tests

extension XCSchemeInfoProfileActionInfoTests {
    func test_runnable() throws {
        let actionInfo = XCSchemeInfo.ProfileActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            topLevelTargetInfos: []
        )
        guard let profileActionInfo = actionInfo else {
            XCTFail("Expected a `ProfileActionInfo`")
            return
        }
        XCTAssertEqual(
            profileActionInfo.runnable?.buildableReference,
            appTargetInfo.buildableReference
        )
    }
}

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoProfileActionInfoTests {
    func test_customSchemeInit_noProfileAction() throws {
        let actual = try XCSchemeInfo.ProfileActionInfo(
            profileAction: nil,
            defaultBuildConfigurationName: "Random",
            targetResolver: targetResolver,
            targetIDsByLabelAndConfiguration: [:]
        )
        XCTAssertNil(actual)
    }

    func test_customSchemeInit_withProfileAction() throws {
        let actual = try XCSchemeInfo.ProfileActionInfo(
            profileAction: xcodeScheme.profileAction,
            defaultBuildConfigurationName: appTarget
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
        let expected = XCSchemeInfo.ProfileActionInfo(
            buildConfigurationName: expectedTargetInfo.pbxTarget
                .defaultBuildConfigurationName,
            targetInfo: expectedTargetInfo
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoProfileActionInfoTests: XCTestCase {
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

    lazy var appPlatform = Fixtures.targets["A 2"]!.platform

    lazy var appTarget = pbxTargetsDict["A 2"]!

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
        platforms: [appPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    lazy var xcodeScheme = try! XcodeScheme(
        name: "My Scheme",
        launchAction: .init(target: targetResolver.targets["A 2"]!.label),
        profileAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}
