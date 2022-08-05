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

// MARK: - `allPBXTargets` Tests

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

// MARK: - `wasCreatedForAppExtension` Tests

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

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoTests {
    func test_customSchemeInit() throws {
        let actual = try XCSchemeInfo(
            scheme: xcodeScheme,
            targetResolver: targetResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel
        )
        let expected = try XCSchemeInfo(
            name: schemeName,
            buildActionInfo: try .init(
                targetInfos: [
                    try targetResolver.targetInfo(targetID: "A 1"),
                    try targetResolver.targetInfo(targetID: "A 2"),
                    try targetResolver.targetInfo(targetID: "B 2"),
                ]
            ),
            testActionInfo: try .init(
                buildConfigurationName: .defaultBuildConfigurationName,
                targetInfos: [try targetResolver.targetInfo(targetID: "B 2")]
            ),
            launchActionInfo: try .init(
                buildConfigurationName: .defaultBuildConfigurationName,
                targetInfo: try targetResolver.targetInfo(targetID: "A 2")
            ),
            profileActionInfo: .init(
                buildConfigurationName: .defaultBuildConfigurationName,
                targetInfo: try targetResolver.targetInfo(targetID: "A 2")
            )
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoTests: XCTestCase {
    let schemeName = "Foo"
    let buildConfigurationName = "Bar"

    let xcodeprojBazelLabel = BazelLabel("//foo")

    lazy var filePathResolver = FilePathResolver(
        externalDirectory: "/some/bazel9/external",
        bazelOutDirectory: "/some/bazel9/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )

    lazy var pbxTargetsDict = targetResolver.pbxTargets

    lazy var libraryPlatform = Fixtures.targets["A 1"]!.platform
    lazy var appPlatform = Fixtures.targets["A 2"]!.platform
    lazy var unitTestPlatform = Fixtures.targets["B 2"]!.platform
    lazy var widgetKitExtPlatform = Fixtures.targets["WDKE"]!.platform

    lazy var libraryPBXTarget = pbxTargetsDict["A 1"]!
    lazy var appPBXTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!
    lazy var widgetKitExtPBXTarget = pbxTargetsDict["WDKE"]!

    lazy var appHostInfo = XCSchemeInfo.HostInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: filePathResolver.containerReference,
        index: 0
    )

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestPBXTarget,
        platforms: [unitTestPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [appHostInfo],
        extensionPointIdentifiers: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtPBXTarget,
        platforms: [widgetKitExtPlatform],
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )

    lazy var xcodeScheme = XcodeScheme(
        name: schemeName,
        buildAction: .init(targets: [targetResolver.targets["A 1"]!.label]),
        testAction: .init(targets: [targetResolver.targets["B 2"]!.label]),
        launchAction: .init(target: targetResolver.targets["A 2"]!.label),
        profileAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}
