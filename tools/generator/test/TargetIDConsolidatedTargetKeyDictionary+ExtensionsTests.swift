import XCTest

@testable import generator

// MARK: `collectPlatformsByKey` Tests

extension TargetIDConsolidatedTargetKeyDictionaryExtensionsTests {
    func test_collectPlatformsByKey_notEmpty() throws {
        let result = try consolidatedTargetKeys.collectPlatformsByKey(targets: targets)
        let expected: [ConsolidatedTarget.Key: Set<Platform>] = [
            aKey: [iOSDevicePlatform, iOSSimulatorPlatform],
            bKey: [iOSDevicePlatform],
        ]
        XCTAssertEqual(result, expected)
    }

    func test_collectPlatformsByKey_empty() throws {
        let consolidatedTargetKeys = [TargetID: ConsolidatedTarget.Key]()
        let result = try consolidatedTargetKeys.collectPlatformsByKey(targets: targets)
        let expected: [ConsolidatedTarget.Key: Set<Platform>] = [:]
        XCTAssertEqual(result, expected)
    }
}

// swiftlint:disable:next type_name
class TargetIDConsolidatedTargetKeyDictionaryExtensionsTests: XCTestCase {
    let iOSDevicePlatform = Platform.device(os: .iOS)
    let iOSSimulatorPlatform = Platform.simulator(os: .iOS)

    let aProduct = Product(
        type: .staticLibrary,
        name: "A",
        path: .generated("path/A.a")
    )
    let bProduct = Product(
        type: .staticLibrary,
        name: "B",
        path: .generated("path/B.a")
    )

    let a1TargetID = TargetID("A 1")
    let a2TargetID = TargetID("A 2")
    let b1TargetID = TargetID("B 1")

    lazy var a1Target = Target.mock(platform: iOSDevicePlatform, product: aProduct)
    lazy var a2Target = Target.mock(platform: iOSSimulatorPlatform, product: aProduct)
    lazy var b1Target = Target.mock(platform: iOSDevicePlatform, product: bProduct)

    lazy var aKey = ConsolidatedTarget.Key([a1TargetID, a2TargetID])
    lazy var bKey = ConsolidatedTarget.Key([b1TargetID])

    lazy var targets = [
        a1TargetID: a1Target,
        a2TargetID: a2Target,
        b1TargetID: b1Target,
    ]

    lazy var consolidatedTargetKeys = [
        a1TargetID: aKey,
        a2TargetID: aKey,
        b1TargetID: bKey,
    ]
}
