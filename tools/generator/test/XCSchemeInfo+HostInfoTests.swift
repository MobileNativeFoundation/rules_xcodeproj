import XCTest

@testable import generator

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

class XCSchemeInfoHostInfoTests: XCTestCase {
    let iOSDevicePlatform = Platform.device(os: .iOS)
    let iOSSimulatorPlatform = Platform.simulator(os: .iOS)

    lazy var filePathResolver = FilePathResolver(
        externalDirectory: "/some/bazel17/external",
        bazelOutDirectory: "/some/bazel17/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )
}
