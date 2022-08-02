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
                targetInfos: [unresolvedLibraryTargetInfoWithHosts]
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
        guard let targetInfo = buildActionInfo.targetInfos.first else {
            XCTFail("Expected a `TargetInfo`")
            return
        }
        let selectedHostInfo = try targetInfo.selectedHostInfo
        XCTAssertEqual(selectedHostInfo, unitTestHostInfo)
    }
}

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoBuildActionInfoTests {
    func test_customSchemeInit_noBuildAction() throws {
        let actual = try XCSchemeInfo.BuildActionInfo(
            buildAction: nil,
            targetResolver: targetResolver,
            targetIDsByLabel: [:]
        )
        XCTAssertNil(actual)
    }

    func test_customSchemeInit_withBuildAction() throws {
        let actual = try XCSchemeInfo.BuildActionInfo(
            buildAction: xcodeScheme.buildAction,
            targetResolver: targetResolver,
            targetIDsByLabel: try xcodeScheme.resolveTargetIDs(
                targetResolver: targetResolver,
                xcodeprojBazelLabel: xcodeprojBazelLabel
            )
        )
        let expected = try XCSchemeInfo.BuildActionInfo(
            targetInfos: [try targetResolver.targetInfo(targetID: "A 1")]
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoBuildActionInfoTests: XCTestCase {
    let xcodeprojBazelLabel = BazelLabel("//foo")

    lazy var filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )

    lazy var pbxTargetsDict = targetResolver.pbxTargets

    lazy var libraryTarget = pbxTargetsDict["A 1"]!
    lazy var appTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestTarget = pbxTargetsDict["B 2"]!

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        index: 0
    )
    lazy var unitTestHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: unitTestTarget,
        referencedContainer: filePathResolver.containerReference,
        index: 1
    )

    lazy var unresolvedLibraryTargetInfoWithHosts = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [appHostInfo, unitTestHostInfo],
        extensionPointIdentifiers: []
    )

    lazy var topLevelTargetInfos: [XCSchemeInfo.TargetInfo] = [
        .init(
            pbxTarget: unitTestTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
    ]

    lazy var xcodeScheme = XcodeScheme(
        name: "My Scheme",
        buildAction: .init(targets: [targetResolver.targets["A 1"]!.label]),
        launchAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}
