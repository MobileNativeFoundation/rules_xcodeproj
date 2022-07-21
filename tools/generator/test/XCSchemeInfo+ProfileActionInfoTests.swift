import XcodeProj
import XCTest

@testable import generator

// MARK: Host Resolution Tests

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
            XCTFail("Expected a `ProfileActionInfo`.")
            return
        }
        XCTAssertNotEqual(profileActionInfo.targetInfo.hostResolution, .unresolved)
    }
}

// MARK: runnable Tests

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
            XCTFail("Expected a `ProfileActionInfo`.")
            return
        }
        XCTAssertEqual(
            profileActionInfo.runnable?.buildableReference,
            appTargetInfo.buildableReference
        )
    }
}

// MARK: Test Data

class XCSchemeInfoProfileActionInfoTests: XCTestCase {
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

    lazy var appTarget = pbxTargetsDict["A 2"]!

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
}
