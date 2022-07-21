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
            XCTFail("Expected a `BuildActionInfo`.")
            return
        }
        // We could check for the host resolution not equal to .unresolved. However, by checking for
        // a specific selected host, we are sure that the topLevelTargetInfos was passed along
        // correctly.
        guard let targetInfo = buildActionInfo.targetInfos.first else {
            XCTFail("Expected a `TargetInfo`.")
            return
        }
        let selectedHostInfo = try targetInfo.selectedHostInfo
        XCTAssertEqual(selectedHostInfo, unitTestHostInfo)
    }
}

// MARK: - Test Data

class XCSchemeInfoBuildActionInfoTests: XCTestCase {
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
}
