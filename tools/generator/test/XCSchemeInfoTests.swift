import CustomDump
import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTests {
    func test_init_noActionInfos() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try XCSchemeInfo(
                name: schemeName,
                defaultBuildConfigurationName: "Indy"
            )
        ) {
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
            defaultBuildConfigurationName: "Mike",
            buildActionInfo: .init(
                targets: [libraryTargetInfo].map { .init(targetInfo: $0, buildFor: .allEnabled) }
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
            defaultBuildConfigurationName: "Marcus",
            buildActionInfo: .init(
                targets: [libraryTargetInfo].map { .init(targetInfo: $0, buildFor: .allEnabled) }
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
            defaultBuildConfigurationName: "Sue",
            buildActionInfo: .init(
                targets: [libraryTargetInfo].map { .init(targetInfo: $0, buildFor: .allEnabled) }
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
            defaultBuildConfigurationName: "Joe",
            buildActionInfo: .init(
                targets: [libraryTargetInfo].map { .init(targetInfo: $0, buildFor: .allEnabled) }
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
        XCTAssertNoDifference(pbxTargets, .init([
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
            defaultBuildConfigurationName: "Larry",
            buildActionInfo: .init(
                targets: [libraryTargetInfo].map { .init(targetInfo: $0, buildFor: .allEnabled) }
            )
        )
        XCTAssertFalse(schemeInfo.wasCreatedForAppExtension)
    }

    func test_wasCreatedForAppExtension_withExtension() throws {
        let schemeInfo = try XCSchemeInfo(
            name: schemeName,
            defaultBuildConfigurationName: "Marry",
            buildActionInfo: .init(
                targets: [libraryTargetInfo].map { .init(targetInfo: $0, buildFor: .allEnabled) }
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
            scheme: xcodeScheme.withDefaults,
            xcodeConfigurations: targetResolver.targets["A 1"]!
                .xcodeConfigurations,
            defaultBuildConfigurationName: "Profile",
            targetResolver: targetResolver,
            runnerLabel: runnerLabel,
            args: [:],
            envs: [:]
        )
        let expectedTestTargetInfo = try targetResolver
            .targetInfo(targetID: "B 2")
        let expectedLaunchTargetInfo = try targetResolver
            .targetInfo(targetID: "A 2")
        let expectedProfileTargetInfo = expectedLaunchTargetInfo
        let expected = try XCSchemeInfo(
            name: schemeName,
            defaultBuildConfigurationName: "Profile",
            buildActionInfo: .init(
                targets: [
                    try .init(
                        targetInfo: targetResolver.targetInfo(targetID: "A 1"),
                        buildFor: .allEnabled
                    ),
                    try .init(
                        targetInfo: targetResolver.targetInfo(targetID: "A 2"),
                        buildFor: .init(
                            running: .enabled,
                            profiling: .enabled,
                            archiving: .enabled,
                            analyzing: .enabled
                        )
                    ),
                    try .init(
                        targetInfo: targetResolver.targetInfo(targetID: "B 2"),
                        buildFor: .init(testing: .enabled, analyzing: .enabled)
                    ),
                ]
            ),
            testActionInfo: .init(
                buildConfigurationName: expectedTestTargetInfo.pbxTarget
                    .defaultBuildConfigurationName,
                targetInfos: [expectedTestTargetInfo],
                expandVariablesBasedOn: targetResolver.targetInfo(targetID: "B 2")
            ),
            launchActionInfo: .init(
                buildConfigurationName: expectedLaunchTargetInfo.pbxTarget
                    .defaultBuildConfigurationName,
                targetInfo: expectedLaunchTargetInfo
            ),
            profileActionInfo: .init(
                buildConfigurationName: expectedProfileTargetInfo.pbxTarget
                    .defaultBuildConfigurationName,
                targetInfo: expectedProfileTargetInfo
            )
        )
        XCTAssertNoDifference(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoTests: XCTestCase {
    let schemeName = "Foo"
    let buildConfigurationName = "Bar"

    let runnerLabel = BazelLabel("//foo")

    let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )

    // We must retain in order to retain some sub-objects (like
    // `XCConfigurationList`)
    private let pbxProj = Fixtures.pbxProj()

    lazy var targetResolver = Fixtures.targetResolver(
        pbxProj: pbxProj,
        directories: directories,
        referencedContainer: directories.containerReference
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
        referencedContainer: directories.containerReference,
        index: 0
    )

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryPBXTarget,
        platforms: [libraryPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appPBXTarget,
        platforms: [appPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestPBXTarget,
        platforms: [unitTestPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [appHostInfo],
        extensionPointIdentifiers: []
    )
    lazy var widgetKitExtTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: widgetKitExtPBXTarget,
        platforms: [widgetKitExtPlatform],
        referencedContainer: directories.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: [Fixtures.extensionPointIdentifiers["WDKE"]!]
    )

    lazy var xcodeScheme = try! XcodeScheme(
        name: schemeName,
        // swiftlint:disable:next force_try
        buildAction: try! .init(targets: [.init(label: targetResolver.targets["A 1"]!.label)]),
        testAction: try! .init(targets: [targetResolver.targets["B 2"]!.label]),
        launchAction: .init(target: targetResolver.targets["A 2"]!.label),
        profileAction: .init(target: targetResolver.targets["A 2"]!.label)
    )
}
