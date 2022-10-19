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
            targetResolver: targetResolver,
            targetIDsByLabel: [:]
        )
        XCTAssertNil(actual)
    }

    func test_customSchemeInit_withProfileAction() throws {
        let actual = try XCSchemeInfo.ProfileActionInfo(
            profileAction: xcodeScheme.profileAction,
            targetResolver: targetResolver,
            targetIDsByLabel: try xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                runnerLabel: runnerLabel
            )
        )
        let expected = XCSchemeInfo.ProfileActionInfo(
            buildConfigurationName: .defaultBuildConfigurationName,
            targetInfo: try targetResolver.targetInfo(targetID: "A 2")
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoProfileActionInfoTests: XCTestCase {
    let buildConfigurationName = "Foo"

    let runnerLabel = BazelLabel("//foo")

    let directories = FilePathResolver.Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        external: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/external",
        bazelOut: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/com_github_buildbuddy_io_rules_xcodeproj/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        bazelIntegration: "bazel",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )
    lazy var filePathResolver = FilePathResolver(
        directories: directories
    )

    lazy var targetResolver = Fixtures.targetResolver(
        directories: directories,
        referencedContainer: filePathResolver.containerReference
    )

    lazy var pbxTargetsDict = targetResolver.pbxTargets

    lazy var appPlatform = Fixtures.targets["A 2"]!.platform

    lazy var appTarget = pbxTargetsDict["A 2"]!

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
        platforms: [appPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    lazy var xcodeScheme = try! XcodeScheme(
        name: "My Scheme",
        launchAction: .init(target: targetResolver.targets["A 2"]!.label),
        profileAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}
