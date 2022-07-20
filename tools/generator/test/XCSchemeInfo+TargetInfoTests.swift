import XcodeProj
import XCTest

@testable import generator

// MARK: XCSchemeInfo.TargetInfo Tests

extension XCSchemeInfoTargetInfoTests {
    func test_init() throws {
        XCTAssertEqual(libraryTargetInfo.pbxTarget, libraryTarget)
        XCTAssertEqual(libraryTargetInfo.buildableReference, .init(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference
        ))
    }

    func test_init_hostResolution_noHosts_withoutTopLevelTargets() throws {
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        )
        XCTAssertEqual(targetInfo.hostResolution, .unresolved)

        let resolvedTargetInfo = XCSchemeInfo.TargetInfo(
            resolveHostFor: targetInfo,
            topLevelTargetInfos: []
        )
        XCTAssertEqual(resolvedTargetInfo.hostResolution, .none)
    }

    func test_init_hostResolution_withHosts_withoutTopLevelTargets() throws {
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [appHostInfo, unitTestHostInfo],
            extensionPointIdentifiers: []
        )
        XCTAssertEqual(targetInfo.hostResolution, .unresolved)

        let resolvedTargetInfo = XCSchemeInfo.TargetInfo(
            resolveHostFor: targetInfo,
            topLevelTargetInfos: []
        )
        if case let .selected(selectedHostInfo) = resolvedTargetInfo.hostResolution {
            XCTAssertEqual(selectedHostInfo, appHostInfo)
        } else {
            XCTFail("Expected a selected host.")
        }
    }

    func test_init_hostResolution_withHosts_withTopLevelTargets() throws {
        let topLevelTargetInfos: [XCSchemeInfo.TargetInfo] = [
            .init(
                pbxTarget: unitTestTarget,
                referencedContainer: filePathResolver.containerReference,
                hostInfos: [],
                extensionPointIdentifiers: []
            ),
        ]
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [appHostInfo, unitTestHostInfo],
            extensionPointIdentifiers: []
        )
        XCTAssertEqual(targetInfo.hostResolution, .unresolved)

        let resolvedTargetInfo = XCSchemeInfo.TargetInfo(
            resolveHostFor: targetInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
        if case let .selected(selectedHostInfo) = resolvedTargetInfo.hostResolution {
            XCTAssertEqual(selectedHostInfo, unitTestHostInfo)
        } else {
            XCTFail("Expected a selected host.")
        }
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_selectedHostInfo_unresolved() throws {
        XCTAssertThrowsError(try unresolvedLibraryTargetInfo.selectedHostInfo)
    }

    func test_selectedHostInfo_none() throws {
        let selectedHostInfo = try libraryTargetInfo.selectedHostInfo
        XCTAssertNil(selectedHostInfo)
    }

    func test_selectedHostInfo_selected() throws {
        let selectedHostInfo = try libraryTargetInfoWithHosts.selectedHostInfo
        XCTAssertNotNil(selectedHostInfo)
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_buildableReferences_noHost() throws {
        let buildableReferences = libraryTargetInfo.buildableReferences
        XCTAssertEqual(buildableReferences, [libraryTargetInfo.buildableReference])
    }

    func test_buildableReferences_withHost() throws {
        let buildableReferences = libraryTargetInfoWithHosts.buildableReferences
        XCTAssertEqual(buildableReferences, [
            libraryTargetInfo.buildableReference,
            try libraryTargetInfoWithHosts.selectedHostInfo!.buildableReference,
        ])
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_bazelBuildPreAction_nonNativeTarget() throws {
        let productFileReference = PBXFileReference(
            path: "MyChicken.app"
        )
        let pbxTarget = PBXTarget(
            name: "chicken",
            productName: "MyChicken",
            product: productFileReference
        )
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: pbxTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        )
        let preAction = try targetInfo.bazelBuildPreAction
        XCTAssertNil(preAction)
    }

    func test_bazelBuildPreAction_nativeTarget_noHost() throws {
        let preAction = try libraryTargetInfo.bazelBuildPreAction
        XCTAssertEqual(preAction, .init(
            bazelBuildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: nil
        ))
    }

    func test_bazelBuildPreAction_nativeTarget_withHost() throws {
        let preAction = try libraryTargetInfoWithHosts.bazelBuildPreAction
        let expectedHostIndex = try libraryTargetInfoWithHosts.selectedHostInfo?.index
        XCTAssertNotNil(expectedHostIndex)
        XCTAssertEqual(preAction, .init(
            bazelBuildFor: libraryTargetInfoWithHosts.buildableReference,
            name: libraryTargetInfoWithHosts.pbxTarget.name,
            hostIndex: expectedHostIndex
        ))
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_isWidgetKitExtension() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_productType() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_buildableReferences() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_buildActionEntries() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_bazelBuildPreActions() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

// MARK: Test Data

class XCSchemeInfoTargetInfoTests: XCTestCase {
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

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unresolvedLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unresolvedLibraryTargetInfoWithHosts = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [appHostInfo, unitTestHostInfo],
        extensionPointIdentifiers: []
    )

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: unresolvedLibraryTargetInfo,
        topLevelTargetInfos: []
    )
    lazy var libraryTargetInfoWithHosts = XCSchemeInfo.TargetInfo(
        resolveHostFor: unresolvedLibraryTargetInfoWithHosts,
        topLevelTargetInfos: []
    )
}
