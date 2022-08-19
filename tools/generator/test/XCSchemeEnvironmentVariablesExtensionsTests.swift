import XcodeProj
import XCTest

@testable import generator

extension XCSchemeEnvironmentVariablesExtensionsTests {
    func test_sortedByVariable() throws {
        let envVars: [XCScheme.EnvironmentVariable] = [
            .init(variable: "zebra", value: "hello", enabled: true),
            .init(variable: "apple", value: "goodbye", enabled: true),
        ]
        let expected: [XCScheme.EnvironmentVariable] = [
            .init(variable: "apple", value: "goodbye", enabled: true),
            .init(variable: "zebra", value: "hello", enabled: true),
        ]
        XCTAssertEqual(envVars.sortedLocalizedStandard(), expected)
    }
}

extension XCSchemeEnvironmentVariablesExtensionsTests {
    func test_merged_with() throws {
        let envVars: [XCScheme.EnvironmentVariable] = [
            .init(variable: "apple", value: "goodbye", enabled: true),
            .init(variable: "zebra", value: "hello", enabled: true),
        ]
        let others: [XCScheme.EnvironmentVariable] = [
            .init(variable: "apple", value: "not goodbye", enabled: true),
            .init(variable: "monkey", value: "middle", enabled: true),
        ]
        let expected: [XCScheme.EnvironmentVariable] = [
            .init(variable: "apple", value: "not goodbye", enabled: true),
            .init(variable: "monkey", value: "middle", enabled: true),
            .init(variable: "zebra", value: "hello", enabled: true),
        ]
        let actual = envVars.merged(with: others)
        XCTAssertEqual(actual, expected)
    }
}

// swiftlint:disable:next type_name
class XCSchemeEnvironmentVariablesExtensionsTests: XCTestCase {}
