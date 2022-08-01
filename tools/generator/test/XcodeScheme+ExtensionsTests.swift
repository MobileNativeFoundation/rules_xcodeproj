import XcodeProj
import XCTest

@testable import generator

// MARK: allBazelLabels Tests

extension XcodeSchemeExtensionsTests {
    func test_allBazelLabels_doNotOverwriteTopLevel() throws {
        // Ensure that toolLabel comes through as top-level even though it
        // is specified in build action as well.
        let scheme = XcodeScheme(
            name: "Foo",
            buildAction: .init(targets: [libLabel, toolLabel]),
            testAction: nil,
            launchAction: .init(
                target: toolLabel,
                buildConfigurationName: buildConfigurationName,
                args: [],
                env: [:],
                workingDirectory: nil
            )
        )
        let actual = scheme.allBazelLabels
        let expected: Set<BazelLabel> = [libLabel, toolLabel]
        XCTAssertEqual(expected, actual)
    }

    func test_allBazelLabels_forToolScheme() throws {
        let actual = toolScheme.allBazelLabels
        let expected: Set<BazelLabel> = [libLabel, toolLabel]
        XCTAssertEqual(expected, actual)
    }
}

// MARK: resolveTargetIDs Tests

extension XcodeSchemeExtensionsTests {
    func test_resolveTargetIDs_withToolScheme() throws {
        let actual = try toolScheme.resolveTargetIDs(targetResolver: targetResolver)
        let expected = [
            libLabel: libmacOSx8664TargetID,
            toolLabel: toolmacOSx8664TargetID,
        ]
        XCTAssertEqual(expected, actual)
    }

    func test_resolveTargetIDs_withIOSAppScheme() throws {
        // Confirm that a scheme with multiple top-level targets works.
        // Both the device and simulator TargetID values are available.
        // Prefer the TargetID values for the simulator.
        // We are also ensuring that the watchOS app that is a dependency of this iOS app is not
        // selected.
        let actual = try iOSAppScheme.resolveTargetIDs(targetResolver: targetResolver)
        let expected = [
            libLabel: libiOSx8664TargetID,
            libTestsLabel: libTestsiOSx8664TargetID,
            iOSAppLabel: iOSAppiOSx8664TargetID,
        ]
        XCTAssertEqual(expected, actual)
    }

    func test_resolveTargetIDs_withTVOSAppScheme() throws {
        // Both the device and simulator TargetID values are available.
        // Prefer the TargetID values for the simulator.
        let actual = try tvOSAppScheme.resolveTargetIDs(targetResolver: targetResolver)
        let expected = [
            libLabel: libtvOSx8664TargetID,
            tvOSAppLabel: tvOSApptvOSx8664TargetID,
        ]
        XCTAssertEqual(expected, actual)
    }
}

// MARK: `buildActionWithAllTargets` Tests

extension XcodeSchemeExtensionsTests {
    func test_buildActionWithAllTargets_noOriginal() throws {
        let scheme = XcodeScheme(
            name: "Foo",
            testAction: .init(targets: [libTestsLabel]),
            launchAction: .init(target: iOSAppLabel)
        )
        let expected = XcodeScheme.BuildAction(targets: [iOSAppLabel, libTestsLabel])
        XCTAssertEqual(scheme.buildActionWithAllTargets, expected)
    }

    func test_buildActionWithAllTargets_withOriginal() throws {
        let scheme = XcodeScheme(
            name: "Foo",
            buildAction: .init(targets: [libLabel]),
            testAction: .init(targets: [libTestsLabel]),
            launchAction: .init(target: iOSAppLabel)
        )
        let expected = XcodeScheme.BuildAction(targets: [iOSAppLabel, libTestsLabel, libLabel])
        XCTAssertEqual(scheme.buildActionWithAllTargets, expected)
    }
}

// MARK: `LabelTargetInfo` Tests

extension XcodeSchemeExtensionsTests {
    func test_LabelTargetInfo_best_noTargets() throws {
        let targetInfo = XcodeScheme.LabelTargetInfo(label: "//foo", isTopLevel: false)

        var thrown: Error?
        XCTAssertThrowsError(try targetInfo.best) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected `PreconditionError`.")
            return
        }
        XCTAssertEqual(preconditionError.message, """
Unable to find the best `TargetWithID` for "//foo:foo"
""")
    }

    func test_LabelTargetInfo_best_withTargets() throws {
        XCTAssertEqual(try iOSAppLabelTargetInfo.best, iOSAppiOSx8664TargetWithID)
    }
}

extension XcodeSchemeExtensionsTests {
    func test_LabelTargetInfo_firstCompatibleWith_withCompatibleTarget() throws {
        let actual = iOSAppLabelTargetInfo.firstCompatibleWith(anyOf: [iphoneOSPlatform])
        XCTAssertEqual(actual, iOSAppiOSarm64TargetWithID)
    }

    func test_LabelTargetInfo_firstCompatibleWith_noCompatibleTarget() throws {
        let actual = iOSAppLabelTargetInfo.firstCompatibleWith(anyOf: [appletvOSPlatform])
        XCTAssertNil(actual)
    }
}

// MARK: Test Data

// swiftlint:disable:next type_body_length
class XcodeSchemeExtensionsTests: XCTestCase {
    // Labels

    let libLabel: BazelLabel = "//examples/multiplatform/Lib:Lib"
    let libTestsLabel: BazelLabel = "//examples/multiplatform/LibTests:LibTests.__internal__.__test_bundle"
    let toolLabel: BazelLabel = "//examples/multiplatform/Tool:Tool"
    let iOSAppLabel: BazelLabel = "//examples/multiplatform/iOSApp:iOSApp"
    let tvOSAppLabel: BazelLabel = "//examples/multiplatform/tvOSApp:tvOSApp"
    let watchOSAppLabel: BazelLabel = "//examples/multiplatform/watchOSApp:watchOSApp"

    // Configurations

    let iOSarm64Configuration = "ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-2427ca916465"
    let iOSx8664Configuration = "ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-d619bc5eae76"
    let macOSx8664Coniguration = "macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-7373f6dcb398"
    let tvOSarm64Configuration = "tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-90aac610cf68"
    let tvOSx8664Configuration = "tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-9d824d5ada9f"
    let watchOSarm64Configuration = "watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-ffdc9fd07085"
    let watchOSx8664Configuration = "watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-cd006600ac60"
    let applebinMacOSDarwinx8664Configuration = "applebin_macos-darwin_x86_64-dbg-ST-7373f6dcb398"
    let applebiniOSiOSarm64Configuration = "applebin_ios-ios_arm64-dbg-ST-2427ca916465"
    let applebiniOSiOSx8664Configuration = "applebin_ios-ios_x86_64-dbg-ST-d619bc5eae76"
    let applebintvOStvOSarm64Configuration = "applebin_tvos-tvos_arm64-dbg-ST-90aac610cf68"
    let applebintvOStvOSx8664Configuration = "applebin_tvos-tvos_x86_64-dbg-ST-9d824d5ada9f"
    let applebinwatchOSwatchOSarm64Configuration = "applebin_watchos-watchos_arm64_32-dbg-ST-ffdc9fd07085"
    let applebinwatchOSwatchOSx8664Configuration = "applebin_watchos-watchos_x86_64-dbg-ST-cd006600ac60"
    let macOSx8664Configuration = "macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-7373f6dcb398"

    // Platforms

    let appletvOSPlatform = Platform(
        os: .tvOS,
        variant: .tvOSDevice,
        arch: "arm64",
        minimumOsVersion: "15.0"
    )
    let appletvSimulatorPlatform = Platform(
        os: .tvOS,
        variant: .tvOSSimulator,
        arch: "x86_64",
        minimumOsVersion: "15.0"
    )
    let iphoneOSPlatform = Platform(
        os: .iOS,
        variant: .iOSDevice,
        arch: "arm64",
        minimumOsVersion: "15.0"
    )
    let iphoneSimulatorPlatform = Platform(
        os: .iOS,
        variant: .iOSSimulator,
        arch: "x86_64",
        minimumOsVersion: "15.0"
    )
    let macOSPlatform = Platform(
        os: .macOS,
        variant: .macOS,
        arch: "x86_64",
        minimumOsVersion: "11.0"
    )
    let watchOSPlatform = Platform(
        os: .watchOS,
        variant: .watchOSDevice,
        arch: "arm64_32",
        minimumOsVersion: "7.0"
    )
    let watchSimulatorPlatform = Platform(
        os: .watchOS,
        variant: .watchOSSimulator,
        arch: "x86_64",
        minimumOsVersion: "7.0"
    )

    // Targets and TargetIDs

    lazy var libiOSarm64TargetID: TargetID = .init("\(libLabel) \(iOSarm64Configuration)")
    lazy var libiOSarm64Target = Target.mock(
        label: libLabel,
        configuration: iOSarm64Configuration,
        platform: iphoneOSPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libiOSx8664TargetID: TargetID = .init("\(libLabel) \(iOSx8664Configuration)")
    lazy var libiOSx8664Target = Target.mock(
        label: libLabel,
        configuration: iOSx8664Configuration,
        platform: iphoneSimulatorPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libtvOSarm64TargetID: TargetID = .init("\(libLabel) \(tvOSarm64Configuration)")
    lazy var libtvOSarm64Target = Target.mock(
        label: libLabel,
        configuration: tvOSarm64Configuration,
        platform: appletvOSPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libtvOSx8664TargetID: TargetID = .init("\(libLabel) \(tvOSx8664Configuration)")
    lazy var libtvOSx8664Target = Target.mock(
        label: libLabel,
        configuration: tvOSx8664Configuration,
        platform: appletvSimulatorPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libwatchOSarm64TargetID: TargetID = .init("\(libLabel) \(watchOSarm64Configuration)")
    lazy var libwatchOSarm64Target = Target.mock(
        label: libLabel,
        configuration: watchOSarm64Configuration,
        platform: watchOSPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libwatchOSx8664TargetID: TargetID = .init("\(libLabel) \(watchOSx8664Configuration)")
    lazy var libwatchOSx8664Target = Target.mock(
        label: libLabel,
        configuration: watchOSx8664Configuration,
        platform: watchSimulatorPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libmacOSx8664TargetID: TargetID = .init("\(libLabel) \(macOSx8664Configuration)")
    lazy var libmacOSx8664Target = Target.mock(
        label: libLabel,
        configuration: macOSx8664Configuration,
        platform: macOSPlatform,
        product: .init(
            type: .staticLibrary,
            name: "a",
            path: .generated("z/A.a")
        )
    )

    lazy var libTestsiOSx8664TargetID: TargetID = .init("\(libTestsLabel) \(applebiniOSiOSx8664Configuration)")
    lazy var libTestsiOSx8664Target = Target.mock(
        label: libTestsLabel,
        configuration: applebiniOSiOSx8664Configuration,
        platform: iphoneSimulatorPlatform,
        product: .init(
            type: .unitTestBundle,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [libiOSx8664TargetID]
    )

    lazy var toolmacOSx8664TargetID: TargetID = .init(
        "\(toolLabel) \(applebinMacOSDarwinx8664Configuration)")
    lazy var toolmacOSx8664Target = Target.mock(
        label: toolLabel,
        configuration: applebinMacOSDarwinx8664Configuration,
        platform: macOSPlatform,
        product: .init(
            type: .commandLineTool,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [libmacOSx8664TargetID]
    )

    lazy var iOSAppiOSarm64TargetID: TargetID = .init(
        "\(iOSAppLabel) \(applebiniOSiOSarm64Configuration)")
    lazy var iOSAppiOSarm64Target = Target.mock(
        label: iOSAppLabel,
        configuration: applebiniOSiOSarm64Configuration,
        platform: iphoneOSPlatform,
        product: .init(
            type: .application,
            name: "a",
            path: .generated("z/A.a")
        ),
        // This target has a dependency on a watchOS app
        dependencies: [libiOSarm64TargetID, watchOSAppwatchOSarm64TargetID]
    )

    lazy var iOSAppiOSx8664TargetID: TargetID = .init(
        "\(iOSAppLabel) \(applebiniOSiOSx8664Configuration)")
    lazy var iOSAppiOSx8664Target = Target.mock(
        label: iOSAppLabel,
        configuration: applebiniOSiOSx8664Configuration,
        platform: iphoneSimulatorPlatform,
        product: .init(
            type: .application,
            name: "a",
            path: .generated("z/A.a")
        ),
        // This target has a dependency on a watchOS app
        dependencies: [libiOSx8664TargetID, watchOSAppwatchOSx8664TargetID]
    )

    lazy var tvOSApptvOSarm64TargetID: TargetID = .init(
        "\(tvOSAppLabel) \(applebintvOStvOSarm64Configuration)")
    lazy var tvOSApptvOSarm64Target = Target.mock(
        label: tvOSAppLabel,
        configuration: applebintvOStvOSarm64Configuration,
        platform: appletvOSPlatform,
        product: .init(
            type: .application,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [libtvOSarm64TargetID]
    )

    lazy var tvOSApptvOSx8664TargetID: TargetID = .init(
        "\(tvOSAppLabel) \(applebintvOStvOSx8664Configuration)")
    lazy var tvOSApptvOSx8664Target = Target.mock(
        label: tvOSAppLabel,
        configuration: applebintvOStvOSx8664Configuration,
        platform: appletvSimulatorPlatform,
        product: .init(
            type: .application,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [libtvOSx8664TargetID]
    )

    lazy var watchOSAppwatchOSarm64TargetID: TargetID = .init(
        "\(watchOSAppLabel) \(applebinwatchOSwatchOSarm64Configuration)")
    lazy var watchOSAppwatchOSarm64Target = Target.mock(
        label: watchOSAppLabel,
        configuration: applebinwatchOSwatchOSarm64Configuration,
        platform: watchOSPlatform,
        product: .init(
            type: .watch2App,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [libwatchOSarm64TargetID]
    )

    lazy var watchOSAppwatchOSx8664TargetID: TargetID = .init(
        "\(watchOSAppLabel) \(applebinwatchOSwatchOSx8664Configuration)")
    lazy var watchOSAppwatchOSx8664Target = Target.mock(
        label: watchOSAppLabel,
        configuration: applebinwatchOSwatchOSx8664Configuration,
        platform: watchSimulatorPlatform,
        product: .init(
            type: .watch2App,
            name: "a",
            path: .generated("z/A.a")
        ),
        dependencies: [libwatchOSx8664TargetID]
    )

    lazy var targets: [TargetID: Target] = [
        iOSAppiOSarm64TargetID: iOSAppiOSarm64Target,
        iOSAppiOSx8664TargetID: iOSAppiOSx8664Target,
        libTestsiOSx8664TargetID: libTestsiOSx8664Target,
        libiOSarm64TargetID: libiOSarm64Target,
        libiOSx8664TargetID: libiOSx8664Target,
        libmacOSx8664TargetID: libmacOSx8664Target,
        libtvOSarm64TargetID: libtvOSarm64Target,
        libtvOSx8664TargetID: libtvOSx8664Target,
        libwatchOSarm64TargetID: libwatchOSarm64Target,
        libwatchOSx8664TargetID: libwatchOSx8664Target,
        toolmacOSx8664TargetID: toolmacOSx8664Target,
        tvOSApptvOSarm64TargetID: tvOSApptvOSarm64Target,
        tvOSApptvOSx8664TargetID: tvOSApptvOSx8664Target,
        watchOSAppwatchOSarm64TargetID: watchOSAppwatchOSarm64Target,
        watchOSAppwatchOSx8664TargetID: watchOSAppwatchOSx8664Target,
    ]

    lazy var iOSAppConsolidatedTargetKey = ConsolidatedTarget.Key(
        [iOSAppiOSarm64TargetID, iOSAppiOSx8664TargetID])

    lazy var libTestsConsolidatedTargetKey = ConsolidatedTarget.Key([libTestsiOSx8664TargetID])

    lazy var libiOSConsolidatedTargetKey = ConsolidatedTarget.Key(
        [libiOSarm64TargetID, libiOSx8664TargetID])

    lazy var libmacOSConsolidatedTargetKey = ConsolidatedTarget.Key([libmacOSx8664TargetID])

    lazy var libtvOSConsolidatedTargetKey = ConsolidatedTarget.Key(
        [libtvOSarm64TargetID, libtvOSx8664TargetID])

    lazy var libwatchOSConsolidatedTargetKey = ConsolidatedTarget.Key(
        [libwatchOSarm64TargetID, libwatchOSx8664TargetID])

    lazy var toolmacOSConsolidatedTargetKey = ConsolidatedTarget.Key([toolmacOSx8664TargetID])

    lazy var tvOSAppConsolidatedTargetKey = ConsolidatedTarget.Key(
        [tvOSApptvOSarm64TargetID, tvOSApptvOSx8664TargetID])

    lazy var watchOSAppConsolidatedTargetKey = ConsolidatedTarget.Key(
        [watchOSAppwatchOSarm64TargetID, watchOSAppwatchOSx8664TargetID])

    lazy var consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key] = [
        iOSAppiOSarm64TargetID: iOSAppConsolidatedTargetKey,
        iOSAppiOSx8664TargetID: iOSAppConsolidatedTargetKey,
        libTestsiOSx8664TargetID: libTestsConsolidatedTargetKey,
        libiOSarm64TargetID: libiOSConsolidatedTargetKey,
        libiOSx8664TargetID: libiOSConsolidatedTargetKey,
        libmacOSx8664TargetID: libmacOSConsolidatedTargetKey,
        libtvOSarm64TargetID: libtvOSConsolidatedTargetKey,
        libtvOSx8664TargetID: libtvOSConsolidatedTargetKey,
        libwatchOSarm64TargetID: libwatchOSConsolidatedTargetKey,
        libwatchOSx8664TargetID: libwatchOSConsolidatedTargetKey,
        toolmacOSx8664TargetID: toolmacOSConsolidatedTargetKey,
        tvOSApptvOSarm64TargetID: tvOSAppConsolidatedTargetKey,
        tvOSApptvOSx8664TargetID: tvOSAppConsolidatedTargetKey,
        watchOSAppwatchOSarm64TargetID: watchOSAppConsolidatedTargetKey,
        watchOSAppwatchOSx8664TargetID: watchOSAppConsolidatedTargetKey,
    ]

    lazy var pbxTargets: [ConsolidatedTarget.Key: PBXTarget] = [
        iOSAppConsolidatedTargetKey: .init(name: "iOSApp", productType: .application),
        libTestsConsolidatedTargetKey: .init(name: "libTests", productType: .unitTestBundle),
        libiOSConsolidatedTargetKey: .init(name: "libiOS", productType: .staticLibrary),
        libmacOSConsolidatedTargetKey: .init(name: "libmacOS", productType: .staticLibrary),
        libtvOSConsolidatedTargetKey: .init(name: "libtvOS", productType: .staticLibrary),
        libwatchOSConsolidatedTargetKey: .init(name: "libwatchOS", productType: .staticLibrary),
        toolmacOSConsolidatedTargetKey: .init(name: "toolmacOS", productType: .commandLineTool),
        tvOSAppConsolidatedTargetKey: .init(name: "tvOSApp", productType: .application),
        watchOSAppConsolidatedTargetKey: .init(name: "watchOSApp", productType: .watch2App),
    ]

    lazy var filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    // swiftlint:disable:next force_try
    lazy var targetResolver = try! TargetResolver(
        referencedContainer: filePathResolver.containerReference,
        targets: targets,
        targetHosts: [:],
        extensionPointIdentifiers: [:],
        consolidatedTargetKeys: consolidatedTargetKeys,
        pbxTargets: pbxTargets
    )

    // Schemes

    let buildConfigurationName = "Chicken"

    lazy var toolScheme = XcodeScheme(
        name: "Tool",
        buildAction: .init(targets: [libLabel]),
        testAction: nil,
        launchAction: .init(
            target: toolLabel,
            buildConfigurationName: buildConfigurationName,
            args: [],
            env: [:],
            workingDirectory: nil
        )
    )

    lazy var iOSAppScheme = XcodeScheme(
        name: "iOSApp",
        buildAction: .init(targets: [libLabel]),
        testAction: .init(targets: [libTestsLabel], buildConfigurationName: buildConfigurationName),
        launchAction: .init(
            target: iOSAppLabel,
            buildConfigurationName: buildConfigurationName,
            args: [],
            env: [:],
            workingDirectory: nil
        )
    )

    lazy var tvOSAppScheme = XcodeScheme(
        name: "tvOSApp",
        buildAction: .init(targets: [libLabel]),
        testAction: nil,
        launchAction: .init(
            target: tvOSAppLabel,
            buildConfigurationName: buildConfigurationName,
            args: [],
            env: [:],
            workingDirectory: nil
        )
    )

    lazy var iOSAppiOSarm64TargetWithID = XcodeScheme.TargetWithID(
        id: iOSAppiOSarm64TargetID,
        target: iOSAppiOSarm64Target
    )
    lazy var iOSAppiOSx8664TargetWithID = XcodeScheme.TargetWithID(
        id: iOSAppiOSx8664TargetID,
        target: iOSAppiOSx8664Target
    )
    lazy var iOSAppLabelTargetInfo: XcodeScheme.LabelTargetInfo = {
        var targetInfo = XcodeScheme.LabelTargetInfo(label: iOSAppLabel, isTopLevel: false)
        targetInfo.add(iOSAppiOSarm64TargetWithID)
        targetInfo.add(iOSAppiOSx8664TargetWithID)
        return targetInfo
    }()
}
