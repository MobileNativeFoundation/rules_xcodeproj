import CustomDump
import XCTest

@testable import generator

final class BuildSettingConditionalTests: XCTestCase {
    static let conditionals: [String: BuildSettingConditional] = [
        "A": .init(platform: .init(
            os: .macOS,
            variant: .macOS,
            arch: "arm64",
            minimumOsVersion: "11.0"
        )),
        "B": .init(platform: .init(
            os: .iOS,
            variant: .iOSSimulator,
            arch: "arm64",
            minimumOsVersion: "11.0"
        )),
        "C": .init(platform: .init(
            os: .iOS,
            variant: .iOSDevice,
            arch: "arm64",
            minimumOsVersion: "11.0"
        )),
        "D": .init(platform: .init(
            os: .iOS,
            variant: .iOSSimulator,
            arch: "arm64",
            minimumOsVersion: "11.0"
        )),
        "any": .any,
    ]

    func test_comparable() {
        // Arrange

        let conditionalA = Self.conditionals["A"]!
        let conditionalAny = BuildSettingConditional.any

        // Assert

        XCTAssertFalse(conditionalA < conditionalA)
        XCTAssertEqual(conditionalA, conditionalA)
        XCTAssertFalse(conditionalA > conditionalA)

        XCTAssertFalse(conditionalAny < conditionalAny)
        XCTAssertEqual(conditionalAny, conditionalAny)
        XCTAssertFalse(conditionalAny > conditionalAny)
    }

    func test_sort() {
        // Arrange

        let conditionals = Self.conditionals
        let expectedSortedConditionals = [
            conditionals["any"]!,
            conditionals["A"]!,
            conditionals["B"]!,
            conditionals["D"]!,
            conditionals["C"]!,
        ]

        // Act

        let sortedConditionals = conditionals.values.sorted()

        // Assert

        XCTAssertNoDifference(sortedConditionals, expectedSortedConditionals)
    }

    func test_conditionalize_normal() {
        // Arrange

        let buildSettingKey = "SOME_SETTING"
        let conditionals = Self.conditionals
        let expectedConditionalizedKeys = [
            "SOME_SETTING",
            "SOME_SETTING[sdk=macosx*]",
            "SOME_SETTING[sdk=iphonesimulator*]",
            "SOME_SETTING[sdk=iphoneos*]",
            "SOME_SETTING[sdk=iphonesimulator*]",
        ]

        // Act

        let conditionalizedKeys = [
            conditionals["any"]!.conditionalize(buildSettingKey),
            conditionals["A"]!.conditionalize(buildSettingKey),
            conditionals["B"]!.conditionalize(buildSettingKey),
            conditionals["C"]!.conditionalize(buildSettingKey),
            conditionals["D"]!.conditionalize(buildSettingKey),
        ]

        // Assert

        XCTAssertNoDifference(conditionalizedKeys, expectedConditionalizedKeys)
    }

    func test_conditionalize_archs() {
        // Arrange

        let buildSettingKey = "ARCHS"
        let conditionals = Self.conditionals
        let expectedConditionalizedKeys = [
            "ARCHS",
            "ARCHS[sdk=macosx*]",
            "ARCHS[sdk=iphonesimulator*]",
            "ARCHS[sdk=iphoneos*]",
            "ARCHS[sdk=iphonesimulator*]",
        ]

        // Act

        let conditionalizedKeys = [
            conditionals["any"]!.conditionalize(buildSettingKey),
            conditionals["A"]!.conditionalize(buildSettingKey),
            conditionals["B"]!.conditionalize(buildSettingKey),
            conditionals["C"]!.conditionalize(buildSettingKey),
            conditionals["D"]!.conditionalize(buildSettingKey),
        ]

        // Assert

        XCTAssertNoDifference(conditionalizedKeys, expectedConditionalizedKeys)
    }

    func test_conditionalize_sdkroot() {
        // Arrange

        let buildSettingKey = "SDKROOT"
        let conditionals = Self.conditionals
        let expectedConditionalizedKeys = [
            "SDKROOT",
            "SDKROOT",
            "SDKROOT",
            "SDKROOT",
            "SDKROOT",
        ]

        // Act

        let conditionalizedKeys = [
            conditionals["any"]!.conditionalize(buildSettingKey),
            conditionals["A"]!.conditionalize(buildSettingKey),
            conditionals["B"]!.conditionalize(buildSettingKey),
            conditionals["C"]!.conditionalize(buildSettingKey),
            conditionals["D"]!.conditionalize(buildSettingKey),
        ]

        // Assert

        XCTAssertNoDifference(conditionalizedKeys, expectedConditionalizedKeys)
    }
}
