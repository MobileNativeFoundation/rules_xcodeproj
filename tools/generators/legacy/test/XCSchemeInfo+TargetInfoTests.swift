import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTargetInfoTests {
    func test_init() throws {
        XCTAssertEqual(libraryTargetInfo.pbxTarget, libraryPBXTarget)
        XCTAssertEqual(libraryTargetInfo.buildableReference, .init(
            pbxTarget: libraryPBXTarget,
            referencedContainer: directories.containerReference
        ))
        XCTAssertEqual(
            libraryTargetInfoWithHosts.hostInfos,
            [appHostInfo, anotherAppHostInfo],
            "the hostInfos should be sorted and unique"
        )
    }
}

// MARK: - Host Resolution Tests

extension XCSchemeInfoTargetInfoTests {
    func test_init_hostResolution_noHosts_withoutTopLevelTargets() throws {
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryPBXTarget,
            platforms: [libraryPlatform],
            referencedContainer: directories.containerReference,
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
            pbxTarget: libraryPBXTarget,
            platforms: [libraryPlatform],
            referencedContainer: directories.containerReference,
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
                pbxTarget: anotherAppPBXTarget,
                platforms: [anotherAppPlatform],
                referencedContainer: directories.containerReference,
                hostInfos: [],
                extensionPointIdentifiers: []
            ),
        ]
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryPBXTarget,
            platforms: [libraryPlatform],
            referencedContainer: directories.containerReference,
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

// MARK: - `macroExpansion` Tests

extension XCSchemeInfoTargetInfoTests {
    func test_macroExpansion_hasHostAndIsNotWatchApp() throws {
        guard let macroExpansion = try unitTestTargetInfo.macroExpansion else {
            XCTFail("Expected a `macroExpansion`")
            return
        }
        XCTAssertEqual(macroExpansion, appHostInfo.buildableReference)
    }

    func test_macroExpansion_hasHostAndIsWatchApp() throws {
        XCTAssertNil(try watchAppTargetInfo.macroExpansion)
    }

    func test_macroExpansion_noHostIsTestable() throws {
        guard let macroExpansion = try unitTestNoHostTargetInfo.macroExpansion else {
            XCTFail("Expected a `macroExpansion`")
            return
        }
        XCTAssertEqual(macroExpansion, unitTestNoHostTargetInfo.buildableReference)
    }

    func test_macroExpansion_noHostIsNotTestable() throws {
        XCTAssertNil(try appTargetInfo.macroExpansion)
    }
}

// MARK: - `bazelBuildPreAction` Tests

extension XCSchemeInfoTargetInfoTests {
    func test_bazelBuildPreAction_nativeTarget_noHost() throws {
        let preAction = try libraryTargetInfo.buildPreAction()
        XCTAssertEqual(preAction, .init(
            buildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: nil
        ))
    }

    func test_bazelBuildPreAction_nativeTarget_withHost() throws {
        let preAction = try libraryTargetInfoWithHosts.buildPreAction()
        let expectedHostIndex = try libraryTargetInfoWithHosts.selectedHostInfo?.index
        XCTAssertNotNil(expectedHostIndex)
        XCTAssertEqual(preAction, .init(
            buildFor: libraryTargetInfoWithHosts.buildableReference,
            name: libraryTargetInfoWithHosts.pbxTarget.name,
            hostIndex: expectedHostIndex
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

// MARK: - Sequence bazelBuildPreActions Tests

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_bazelBuildPreActions() throws {
        let targetInfos = [libraryTargetInfo, appTargetInfo]
        let expected: [XCScheme.ExecutionAction] = [
            .initBazelBuildOutputGroupsFile(
                buildableReference: libraryTargetInfo.buildableReference
            ),
            try libraryTargetInfo.buildPreAction(),
            try appTargetInfo.buildPreAction(),
        ]
        XCTAssertEqual(try targetInfos.buildPreActions(), expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoTargetInfoTests: XCTestCase {
    let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )

    lazy var pbxTargetsDict: [ConsolidatedTarget.Key: PBXNativeTarget] =
        Fixtures.pbxTargets(
            in: Fixtures.pbxProj(),
            directories: directories,
            consolidatedTargets: Fixtures.consolidatedTargets
        )
        .0

    lazy var libraryPlatform = Fixtures.targets["A 1"]!.platform
    lazy var appPlatform = Fixtures.targets["A 2"]!.platform
    lazy var anotherAppPlatform = Fixtures.targets["I"]!.platform
    lazy var widgetKitExtPlatform = Fixtures.targets["WDKE"]!.platform
    lazy var unitTestPlatform = Fixtures.targets["B 2"]!.platform
    lazy var watchAppPlatform = Fixtures.targets["W"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var appPBXTarget = pbxTargetsDict["A 2"]!
    lazy var anotherAppPBXTarget = pbxTargetsDict["I"]!
    lazy var widgetKitExtPBXTarget = pbxTargetsDict["WDKE"]!
    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!
    lazy var watchAppPBXTarget = pbxTargetsDict["W"]!

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: directories.containerReference,
        index: 0
    )
    lazy var anotherAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: anotherAppPBXTarget,
        platforms: [anotherAppPlatform],
        referencedContainer: directories.containerReference,
        index: 1
    )

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: appPBXTarget,
            platforms: [appPlatform],
            referencedContainer: directories.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtPBXTarget,
        platforms: [widgetKitExtPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )
    lazy var unresolvedLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unresolvedLibraryTargetInfoWithHosts = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        // Puprposefully specified appHostInfo twice
        hostInfos: [appHostInfo, anotherAppHostInfo, appHostInfo],
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
    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: unitTestPBXTarget,
            platforms: [unitTestPlatform],
            referencedContainer: directories.containerReference,
            hostInfos: [appHostInfo],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var unitTestNoHostTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: unitTestPBXTarget,
            platforms: [unitTestPlatform],
            referencedContainer: directories.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var watchAppTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: watchAppPBXTarget,
            platforms: [watchAppPlatform],
            referencedContainer: directories.containerReference,
            hostInfos: [appHostInfo],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
}
