import XCTest

@testable import generator

// MARK: Initializer Tests

extension XCSchemeInfoHostInfoTests {
    func test_init_storesUniqSortedPlatforms() throws {
        let hostInfo = XCSchemeInfo.HostInfo(
            pbxTarget: try targetResolver.pbxTargetInfos.value(for: "I").pbxTarget,
            // This is purposely not sorted.
            platforms: [iOSDevicePlatform, iOSSimulatorPlatform],
            referencedContainer: filePathResolver.containerReference,
            index: 0
        )
        XCTAssertEqual(hostInfo.platforms, [iOSSimulatorPlatform, iOSDevicePlatform])
    }
}

// MARK: Comparable Tests

extension XCSchemeInfoHostInfoTests {
    func test_Comparable() throws {
        let iOSApp = XCSchemeInfo.HostInfo(
            pbxTargetInfo: try targetResolver.pbxTargetInfos.value(for: "I"),
            index: 0
        )
        let macApp = XCSchemeInfo.HostInfo(
            pbxTargetInfo: try targetResolver.pbxTargetInfos.value(for: "A 2"),
            index: 1
        )
        XCTAssertFalse(iOSApp < macApp, "iOSApp should not be less than macApp")
        XCTAssertTrue(macApp < iOSApp, "macApp should be less than iOSApp")
    }
}

// MARK: Host Resolution Tests

extension XCSchemeInfoHostInfoTests {
    func test_Collection_resolve_isEmpty() throws {
        let hostInfos = [XCSchemeInfo.HostInfo]()
        XCTAssertEqual(hostInfos.resolve(topLevelTargetInfos: topLevelTargetInfos), .none)
    }

    func test_Collection_resolve_matchTopLevelTarget() throws {
        // Make sure the expected host info is not first
        let hostInfos = [watchOSAppHostInfo, macOSAppHostInfo]
        let result = hostInfos.resolve(topLevelTargetInfos: topLevelTargetInfos)
        guard case let .selected(selected) = result else {
            XCTFail("Expected host resolution selected, but was \(result)")
            return
        }
        XCTAssertEqual(selected, macOSAppHostInfo)
    }

    func test_Collection_resolve_matchTopLevelPlatform() throws {
        // Make sure the expected host info is not first
        let hostInfos = [watchOSAppHostInfo, anotheriOSAppHostInfo]
        let result = hostInfos.resolve(topLevelTargetInfos: topLevelTargetInfos)
        guard case let .selected(selected) = result else {
            XCTFail("Expected host resolution selected, but was \(result)")
            return
        }
        XCTAssertEqual(selected, anotheriOSAppHostInfo)
    }

    func test_Collection_resolve_matchFirst() throws {
        let hostInfos = [watchOSAppHostInfo]
        let result = hostInfos.resolve(topLevelTargetInfos: topLevelTargetInfos)
        guard case let .selected(selected) = result else {
            XCTFail("Expected host resolution selected, but was \(result)")
            return
        }
        XCTAssertEqual(selected, watchOSAppHostInfo)
    }
}

// MARK: Test Data

class XCSchemeInfoHostInfoTests: XCTestCase {
    let iOSDevicePlatform = Platform.device(os: .iOS)
    let iOSSimulatorPlatform = Platform.simulator(os: .iOS)

    let directories = FilePathResolver.Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        external: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/external",
        bazelOut: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/com_github_buildbuddy_io_rules_xcodeproj/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )
    lazy var filePathResolver = FilePathResolver(
        directories: directories
    )

    lazy var targetResolver = Fixtures.targetResolver(
        directories: directories,
        referencedContainer: filePathResolver.containerReference
    )

    lazy var macOSAppPBXTargetInfo = targetResolver.pbxTargetInfos["A 2"]!
    lazy var iOSAppPBXTargetInfo = targetResolver.pbxTargetInfos["I"]!
    lazy var anotheriOSAppPBXTargetInfo = targetResolver.pbxTargetInfos["AC"]!
    lazy var watchOSAppPBXTargetInfo = targetResolver.pbxTargetInfos["W"]!

    lazy var macOSAppTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTargetInfo: macOSAppPBXTargetInfo,
        hostInfos: []
    )
    lazy var iOSAppTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTargetInfo: iOSAppPBXTargetInfo,
        hostInfos: []
    )
    lazy var topLevelTargetInfos = [macOSAppTargetInfo, iOSAppTargetInfo]

    lazy var macOSAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTargetInfo: macOSAppPBXTargetInfo,
        index: 3
    )
    lazy var iOSAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTargetInfo: iOSAppPBXTargetInfo,
        index: 2
    )
    lazy var anotheriOSAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTargetInfo: anotheriOSAppPBXTargetInfo,
        index: 4
    )
    lazy var watchOSAppHostInfo = XCSchemeInfo.HostInfo(
        pbxTargetInfo: watchOSAppPBXTargetInfo,
        index: 1
    )
}
