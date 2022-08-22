import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTargetInfoTests {
    func test_init() throws {
        XCTAssertEqual(libraryTargetInfo.pbxTarget, libraryPBXTarget)
        XCTAssertEqual(libraryTargetInfo.buildableReference, .init(
            pbxTarget: libraryPBXTarget,
            referencedContainer: filePathResolver.containerReference
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
            pbxTarget: libraryPBXTarget,
            platforms: [libraryPlatform],
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
                pbxTarget: anotherAppPBXTarget,
                platforms: [anotherAppPlatform],
                referencedContainer: filePathResolver.containerReference,
                hostInfos: [],
                extensionPointIdentifiers: []
            ),
        ]
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryPBXTarget,
            platforms: [libraryPlatform],
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

// MARK: - `macroExpansion` Tests

extension XCSchemeInfoTargetInfoTests {
    func test_macroExpansion_hasHostAndIsNotWatchApp() throws {
        // let actionInfo = try XCSchemeInfo.LaunchActionInfo(
        //     resolveHostsFor: .init(
        //         buildConfigurationName: buildConfigurationName,
        //         targetInfo: unitTestTargetInfo
        //     ),
        //     topLevelTargetInfos: []
        // )
        // guard let launchActionInfo = actionInfo else {
        //     XCTFail("Expected a `LaunchActionInfo`")
        //     return
        // }
        guard let macroExpansion = try unitTestTargetInfo.macroExpansion else {
            XCTFail("Expected a `macroExpansion`")
            return
        }
        XCTAssertEqual(macroExpansion, appHostInfo.buildableReference)
    }

    func test_macroExpansion_hasHostAndIsWatchApp() throws {
        // let actionInfo = try XCSchemeInfo.LaunchActionInfo(
        //     resolveHostsFor: .init(
        //         buildConfigurationName: buildConfigurationName,
        //         targetInfo: watchAppTargetInfo
        //     ),
        //     topLevelTargetInfos: []
        // )
        // guard let launchActionInfo = actionInfo else {
        //     XCTFail("Expected a `LaunchActionInfo`")
        //     return
        // }
        XCTAssertNil(try watchAppTargetInfo.macroExpansion)
    }

    func test_macroExpansion_noHostIsTestable() throws {
        // let actionInfo = try XCSchemeInfo.LaunchActionInfo(
        //     resolveHostsFor: .init(
        //         buildConfigurationName: buildConfigurationName,
        //         targetInfo: unitTestNoHostTargetInfo
        //     ),
        //     topLevelTargetInfos: []
        // )
        // guard let launchActionInfo = actionInfo else {
        //     XCTFail("Expected a `LaunchActionInfo`")
        //     return
        // }
        guard let macroExpansion = try unitTestNoHostTargetInfo.macroExpansion else {
            XCTFail("Expected a `macroExpansion`")
            return
        }
        XCTAssertEqual(macroExpansion, unitTestNoHostTargetInfo.buildableReference)
    }

    func test_macroExpansion_noHostIsNotTestable() throws {
        // let actionInfo = try XCSchemeInfo.LaunchActionInfo(
        //     resolveHostsFor: .init(
        //         buildConfigurationName: buildConfigurationName,
        //         targetInfo: appTargetInfo
        //     ),
        //     topLevelTargetInfos: []
        // )
        // guard let launchActionInfo = actionInfo else {
        //     XCTFail("Expected a `LaunchActionInfo`")
        //     return
        // }
        XCTAssertNil(try appTargetInfo.macroExpansion)
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
            platforms: [.device(os: .iOS)],
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        )
        let preAction = try targetInfo.buildPreAction()
        XCTAssertNil(preAction)
    }

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
            try libraryTargetInfo.buildPreAction()!,
            try appTargetInfo.buildPreAction()!,
        ]
        XCTAssertEqual(try targetInfos.buildPreActions(), expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoTargetInfoTests: XCTestCase {
    lazy var filePathResolver = FilePathResolver(
        workspaceDirectory: "/Users/TimApple/app",
        externalDirectory: "/some/bazel7/external",
        bazelOutDirectory: "/some/bazel7/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var pbxTargetsDict: [ConsolidatedTarget.Key: PBXTarget] =
        Fixtures.pbxTargets(
            in: Fixtures.pbxProj(),
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
        referencedContainer: filePathResolver.containerReference,
        index: 0
    )
    lazy var anotherAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: anotherAppPBXTarget,
        platforms: [anotherAppPlatform],
        referencedContainer: filePathResolver.containerReference,
        index: 1
    )

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: appPBXTarget,
            platforms: [appPlatform],
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtPBXTarget,
        platforms: [widgetKitExtPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )
    lazy var unresolvedLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unresolvedLibraryTargetInfoWithHosts = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: filePathResolver.containerReference,
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
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [appHostInfo],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var unitTestNoHostTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: unitTestPBXTarget,
            platforms: [unitTestPlatform],
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
    lazy var watchAppTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTarget: watchAppPBXTarget,
            platforms: [watchAppPlatform],
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [appHostInfo],
            extensionPointIdentifiers: []
        ),
        topLevelTargetInfos: []
    )
}
