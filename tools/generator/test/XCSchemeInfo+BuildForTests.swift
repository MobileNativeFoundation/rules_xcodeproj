import XCTest

@testable import generator

// MARK: `Value.xcSchemeValue` Tests

extension XCSchemeInfoBuildForTests {
    func test_Value_xcSchemeValue() throws {
        XCTAssertNil(XCSchemeInfo.BuildFor.Value.disabled.xcSchemeValue(.running))
        XCTAssertEqual(XCSchemeInfo.BuildFor.Value.unspecified.xcSchemeValue(.running), .running)
        XCTAssertEqual(XCSchemeInfo.BuildFor.Value.enabled.xcSchemeValue(.running), .running)
    }
}

// MARK: `Value.merged(with:)` Tests

extension XCSchemeInfoBuildForTests {
    enum ExpectedMergeOutput {
        case value(XCSchemeInfo.BuildFor.Value)
        case error(XCSchemeInfo.BuildFor.Value.ValueError)
    }

    func test_Value_merged_with() throws {
        let testData: [(
            value: XCSchemeInfo.BuildFor.Value,
            other: XCSchemeInfo.BuildFor.Value,
            expected: ExpectedMergeOutput
        )] = [
            (value: .unspecified, other: .unspecified, expected: .value(.unspecified)),
            (value: .unspecified, other: .enabled, expected: .value(.enabled)),
            (value: .unspecified, other: .disabled, expected: .value(.disabled)),
            (value: .enabled, other: .unspecified, expected: .value(.enabled)),
            (value: .enabled, other: .enabled, expected: .value(.enabled)),
            (value: .enabled, other: .disabled, expected: .error(.incompatibleMerge)),
            (value: .disabled, other: .unspecified, expected: .value(.disabled)),
            (value: .disabled, other: .enabled, expected: .error(.incompatibleMerge)),
            (value: .disabled, other: .disabled, expected: .value(.disabled)),
        ]

        for (value, other, expected) in testData {
            switch expected {
            case let .value(expectedValue):
                let result = try value.merged(with: other)
                XCTAssertEqual(
                    result,
                    expectedValue,
                    "value: \(value), other: \(other), expected: \(expected)"
                )
            case let .error(expectedError):
                var thrown: Error?
                XCTAssertThrowsError(try value.merged(with: other)) {
                    thrown = $0
                }
                guard let valueError = thrown as? XCSchemeInfo.BuildFor.Value.ValueError else {
                    XCTFail("""
Expected `ValueError`. value: \(value), other: \(other), expected: \(expected)
""")
                    return
                }
                XCTAssertEqual(
                    valueError,
                    expectedError,
                    "value: \(value), other: \(other), expected: \(expected)"
                )
            }
        }
    }
}

// MARK: `BuildFor.xcSchemeValue` Tests

extension XCSchemeInfoBuildForTests {
    func test_BuildFor_xcSchemeValue() throws {
        var buildFor = XCSchemeInfo.BuildFor(
            running: .disabled,
            testing: .disabled,
            profiling: .disabled,
            archiving: .disabled,
            analyzing: .disabled
        )
        XCTAssertEqual(buildFor.xcSchemeValue, [])

        buildFor = XCSchemeInfo.BuildFor(
            running: .enabled,
            testing: .enabled,
            profiling: .enabled,
            archiving: .enabled,
            analyzing: .enabled
        )
        XCTAssertEqual(buildFor.xcSchemeValue, [
            .running,
            .testing,
            .profiling,
            .archiving,
            .analyzing,
        ])

        buildFor = XCSchemeInfo.BuildFor(
            running: .enabled,
            testing: .disabled,
            profiling: .enabled,
            archiving: .disabled,
            analyzing: .disabled
        )
        XCTAssertEqual(buildFor.xcSchemeValue, [.running, .profiling])
    }
}

// MARK: `BuildFor.merge(with:)` Tests

extension XCSchemeInfoBuildForTests {
    func test_BuildFor_merge_with() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

// MARK: Test Data

class XCSchemeInfoBuildForTests: XCTestCase {}
