import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTests {
    func test_init_noActionInfos() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo(name: schemeName)) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo` (\(schemeName)) should have at least one of the following: `buildActionInfo`, \
`testActionInfo`, or `launchActionInfo`.
""")
    }

    func test_init_noName() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo(
            buildActionInfo: .init(
                targetInfos: [libraryTargetInfo]
            )
        )) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo` should have at least one of the following: `name` or `nameClosure`.
""")
    }

    func test_init_withActionInfos() throws {
        let schemeInfo = try XCSchemeInfo(
            name: schemeName,
            buildActionInfo: .init(
                targetInfos: [libraryTargetInfo]
            ),
            testActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo]
            ),
            launchActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            profileActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            analyzeActionInfo: .init(
                buildConfigurationName: buildConfigurationName
            ),
            archiveActionInfo: .init(
                buildConfigurationName: buildConfigurationName
            )
        )
        XCTAssertEqual(schemeInfo.name, schemeName)
        XCTAssertNotNil(schemeInfo.buildActionInfo)
        XCTAssertNotNil(schemeInfo.testActionInfo)
        XCTAssertNotNil(schemeInfo.launchActionInfo)
        XCTAssertNotNil(schemeInfo.analyzeActionInfo)
        XCTAssertNotNil(schemeInfo.archiveActionInfo)
    }

    func test_init_withNameClosure() throws {
        let customName = "Sally"
        let schemeInfo = try XCSchemeInfo(
            buildActionInfo: .init(
                targetInfos: [libraryTargetInfo]
            )
        ) { _, _, _, _ in
            return customName
        }
        XCTAssertEqual(schemeInfo.name, customName)
    }
}

// MARK: allPBXTargets Tests

extension XCSchemeInfoTests {
    func test_allPBXTargets() throws {
        let schemeInfo = try XCSchemeInfo(
            name: schemeName,
            buildActionInfo: .init(
                targetInfos: [libraryTargetInfo]
            ),
            testActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo]
            ),
            launchActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: appTargetInfo
            ),
            profileActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: widgetKitExtTargetInfo
            ),
            analyzeActionInfo: .init(
                buildConfigurationName: buildConfigurationName
            ),
            archiveActionInfo: .init(
                buildConfigurationName: buildConfigurationName
            )
        )
        let pbxTargets = schemeInfo.allPBXTargets
        XCTAssertEqual(pbxTargets, .init([
            libraryTargetInfo.pbxTarget,
            unitTestTargetInfo.pbxTarget,
            appTargetInfo.pbxTarget,
            widgetKitExtTargetInfo.pbxTarget,
        ]))
    }
}

// MARK: wasCreatedForAppExtension Tests

extension XCSchemeInfoTests {
    func test_wasCreatedForAppExtension_withoutExtension() throws {
        let schemeInfo = try XCSchemeInfo(
            name: schemeName,
            buildActionInfo: .init(
                targetInfos: [libraryTargetInfo]
            )
        )
        XCTAssertFalse(schemeInfo.wasCreatedForAppExtension)
    }

    func test_wasCreatedForAppExtension_withExtension() throws {
        let schemeInfo = try XCSchemeInfo(
            name: schemeName,
            buildActionInfo: .init(
                targetInfos: [libraryTargetInfo]
            ),
            launchActionInfo: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfo: widgetKitExtTargetInfo
            )
        )
        XCTAssertTrue(schemeInfo.wasCreatedForAppExtension)
    }
}

// MARK: - Test Data

class XCSchemeInfoTests: XCTestCase {
    let schemeName = "Foo"
    let buildConfigurationName = "Bar"

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
    lazy var widgetKitExtTarget = pbxTargetsDict["WDKE"]!

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        index: 0
    )

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
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
        hostInfos: [appHostInfo],
        extensionPointIdentifiers: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )
}
