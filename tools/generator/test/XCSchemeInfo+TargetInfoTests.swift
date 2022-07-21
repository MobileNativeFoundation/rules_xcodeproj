import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTargetInfoTests {
    func test_init() throws {
        XCTAssertEqual(libraryTargetInfo.pbxTarget, libraryTarget)
        XCTAssertEqual(libraryTargetInfo.buildableReference, .init(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference
        ))
    }
}

// MARK: - Host Resolution Tests

extension XCSchemeInfoTargetInfoTests {
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
            hostInfos: [appHostInfo, anotherAppHostInfo],
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
            XCTFail("Expected a selected host")
        }
    }

    func test_init_hostResolution_withHosts_withTopLevelTargets() throws {
        let topLevelTargetInfos: [XCSchemeInfo.TargetInfo] = [
            .init(
                pbxTarget: anotherAppTarget,
                referencedContainer: filePathResolver.containerReference,
                hostInfos: [],
                extensionPointIdentifiers: []
            ),
        ]
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [appHostInfo, anotherAppHostInfo],
            extensionPointIdentifiers: []
        )
        XCTAssertEqual(targetInfo.hostResolution, .unresolved)

        let resolvedTargetInfo = XCSchemeInfo.TargetInfo(
            resolveHostFor: targetInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
        if case let .selected(selectedHostInfo) = resolvedTargetInfo.hostResolution {
            XCTAssertEqual(selectedHostInfo, anotherAppHostInfo)
        } else {
            XCTFail("Expected a selected host")
        }
    }
}

// MARK: - `selectedHostInfo` Tests

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

// MARK: - `buildableReferences` Tests

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

// MARK: - `bazelBuildPreAction` Tests

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
        let preAction = try targetInfo.buildPreAction(buildMode: .bazel)
        XCTAssertNil(preAction)
    }

    func test_bazelBuildPreAction_nativeTarget_noHost() throws {
        let buildMode = BuildMode.bazel
        let preAction = try libraryTargetInfo.buildPreAction(buildMode: buildMode)
        XCTAssertEqual(preAction, .init(
            buildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: nil,
            buildMode: buildMode
        ))
    }

    func test_bazelBuildPreAction_nativeTarget_withHost() throws {
        let buildMode = BuildMode.bazel
        let preAction = try libraryTargetInfoWithHosts.buildPreAction(buildMode: buildMode)
        let expectedHostIndex = try libraryTargetInfoWithHosts.selectedHostInfo?.index
        XCTAssertNotNil(expectedHostIndex)
        XCTAssertEqual(preAction, .init(
            buildFor: libraryTargetInfoWithHosts.buildableReference,
            name: libraryTargetInfoWithHosts.pbxTarget.name,
            hostIndex: expectedHostIndex,
            buildMode: buildMode
        ))
    }
}

// MARK: - `isWidgetKitExtension` Tests

extension XCSchemeInfoTargetInfoTests {
    func test_isWidgetKitExtension_true() throws {
        XCTAssertTrue(widgetKitExtTargetInfo.isWidgetKitExtension)
    }

    func test_isWidgetKitExtension_false() throws {
        XCTAssertFalse(libraryTargetInfo.isWidgetKitExtension)
    }
}

// MARK: - `productType` Tests

extension XCSchemeInfoTargetInfoTests {
    func test_productType() throws {
        XCTAssertEqual(libraryTargetInfo.productType, .staticLibrary)
    }
}

// MARK: - Sequence buildableReferences Tests

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_buildableReferences() throws {
        let targetInfos = [libraryTargetInfo, appTargetInfo]
        let expected = libraryTargetInfo.buildableReferences + appTargetInfo.buildableReferences
        XCTAssertEqual(targetInfos.buildableReferences, expected)
    }
}

// MARK: - Sequence buildActionEntries Tests

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_buildActionEntries() throws {
        let targetInfos = [libraryTargetInfo, appTargetInfo]
        let expected: [XCScheme.BuildAction.Entry] = [
            .init(withDefaults: libraryTargetInfo.buildableReference),
            .init(withDefaults: appTargetInfo.buildableReference),
        ]
        XCTAssertEqual(targetInfos.buildActionEntries, expected)
    }
}

// MARK: - Sequence bazelBuildPreActions Tests

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_bazelBuildPreActions() throws {
        let buildMode = BuildMode.bazel
        let targetInfos = [libraryTargetInfo, appTargetInfo]
        let expected: [XCScheme.ExecutionAction] = [
            .initBazelBuildOutputGroupsFile,
            try libraryTargetInfo.buildPreAction(buildMode: buildMode)!,
            try appTargetInfo.buildPreAction(buildMode: buildMode)!,
        ]
        XCTAssertEqual(try targetInfos.buildPreActions(buildMode: buildMode), expected)
    }
}

// MARK: - Test Data

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
    lazy var anotherAppTarget = pbxTargetsDict["I"]!
    lazy var widgetKitExtTarget = pbxTargetsDict["WDKE"]!

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        index: 0
    )
    lazy var anotherAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: anotherAppTarget,
        referencedContainer: filePathResolver.containerReference,
        index: 1
    )

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: appTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
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
        hostInfos: [appHostInfo, anotherAppHostInfo],
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
