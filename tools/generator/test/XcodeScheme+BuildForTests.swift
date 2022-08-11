import XCTest

@testable import generator

// MARK: `Value.xcSchemeValue` Tests

extension XcodeSchemeBuildForTests {
    func test_Value_xcSchemeValue() throws {
        XCTAssertNil(XcodeScheme.BuildFor.Value.disabled.xcSchemeValue(.running))
        XCTAssertNil(XcodeScheme.BuildFor.Value.unspecified.xcSchemeValue(.running))
        XCTAssertEqual(XcodeScheme.BuildFor.Value.enabled.xcSchemeValue(.running), .running)
    }
}

// MARK: `Value.merged(with:)` Tests

extension XcodeSchemeBuildForTests {
    enum ExpectedMergeOutput {
        case value(XcodeScheme.BuildFor.Value)
        case error(XcodeScheme.BuildFor.Value.ValueError)
    }

    func test_Value_merged_with() throws {
        let testData: [(
            value: XcodeScheme.BuildFor.Value,
            other: XcodeScheme.BuildFor.Value,
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
                guard let valueError = thrown as? XcodeScheme.BuildFor.Value.ValueError else {
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

    func test_Value_merge_with() throws {
        var value = XcodeScheme.BuildFor.Value.unspecified
        try value.merge(with: .enabled)
        XCTAssertEqual(value, .enabled)
    }
}

// MARK: `Value.isEnabled` Tests

extension XcodeSchemeBuildForTests {
    func test_Value_isEnabled() throws {
        XCTAssertTrue(XcodeScheme.BuildFor.Value.enabled.isEnabled)
        XCTAssertFalse(XcodeScheme.BuildFor.Value.disabled.isEnabled)
        XCTAssertFalse(XcodeScheme.BuildFor.Value.unspecified.isEnabled)
    }
}

// MARK: `Value.isDisabled` Tests

extension XcodeSchemeBuildForTests {
    func test_Value_isDisabled() throws {
        XCTAssertTrue(XcodeScheme.BuildFor.Value.disabled.isDisabled)
        XCTAssertFalse(XcodeScheme.BuildFor.Value.enabled.isDisabled)
        XCTAssertFalse(XcodeScheme.BuildFor.Value.unspecified.isDisabled)
    }
}

// MARK: `Value.enableIfNotDisabled()` Tests

extension XcodeSchemeBuildForTests {
    func test_Value_enableIfNotDisabled() throws {
        var value = XcodeScheme.BuildFor.Value.unspecified
        value.enableIfNotDisabled()
        XCTAssertEqual(value, .enabled)

        value = XcodeScheme.BuildFor.Value.enabled
        value.enableIfNotDisabled()
        XCTAssertEqual(value, .enabled)

        value = XcodeScheme.BuildFor.Value.disabled
        value.enableIfNotDisabled()
        XCTAssertEqual(value, .disabled)
    }
}

// MARK: `BuildFor.xcSchemeValue` Tests

extension XcodeSchemeBuildForTests {
    func test_BuildFor_xcSchemeValue() throws {
        XCTAssertEqual(allDisabledBuildFor.xcSchemeValue, [])

        XCTAssertEqual(allEnabledBuildFor.xcSchemeValue, [
            .running,
            .testing,
            .profiling,
            .archiving,
            .analyzing,
        ])

        let buildFor = XcodeScheme.BuildFor(
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

extension XcodeSchemeBuildForTests {
    func test_BuildFor_merge_with() throws {
        var buildFor = XcodeScheme.BuildFor()
        try buildFor.merge(with: allDisabledBuildFor)
        XCTAssertEqual(buildFor, allDisabledBuildFor)

        buildFor = XcodeScheme.BuildFor()
        try buildFor.merge(with: allEnabledBuildFor)
        XCTAssertEqual(buildFor, allEnabledBuildFor)

        buildFor = XcodeScheme.BuildFor()
        try buildFor.merge(with: allUnspecifiedBuildFor)
        XCTAssertEqual(buildFor, allUnspecifiedBuildFor)

        // Since these are all Value properties, make sure that we have mapped them properly
        let propertyKeyPaths: [
            WritableKeyPath<XcodeScheme.BuildFor, XcodeScheme.BuildFor.Value>
        ] = [
            \.running,
            \.testing,
            \.profiling,
            \.archiving,
            \.analyzing,
        ]
        for keyPath in propertyKeyPaths {
            buildFor = XcodeScheme.BuildFor()
            buildFor[keyPath: keyPath] = .enabled
            try buildFor.merge(with: allUnspecifiedBuildFor)

            var expected = XcodeScheme.BuildFor()
            expected[keyPath: keyPath] = .enabled
            XCTAssertEqual(buildFor, expected)
        }
    }
}

// MARK: `BuildFor` Sequence `merged()` Tests

extension XcodeSchemeBuildForTests {
    func test_BuildFor_Sequence_merged_notEmpty() throws {
        let buildFors: [XcodeScheme.BuildFor] = [
            .init(running: .enabled),
            .init(profiling: .disabled),
        ]
        let result = try buildFors.merged()
        XCTAssertEqual(result, .init(running: .enabled, profiling: .disabled))
    }

    func test_BuildFor_Sequence_merged_empty() throws {
        let buildFors: [XcodeScheme.BuildFor] = []
        let result = try buildFors.merged()
        XCTAssertEqual(result, .init())
    }
}

// MARK: Test Data

class XcodeSchemeBuildForTests: XCTestCase {
    let allUnspecifiedBuildFor = XcodeScheme.BuildFor()
    let allDisabledBuildFor = XcodeScheme.BuildFor(
        running: .disabled,
        testing: .disabled,
        profiling: .disabled,
        archiving: .disabled,
        analyzing: .disabled
    )
    let allEnabledBuildFor = XcodeScheme.BuildFor(
        running: .enabled,
        testing: .enabled,
        profiling: .enabled,
        archiving: .enabled,
        analyzing: .enabled
    )
}
