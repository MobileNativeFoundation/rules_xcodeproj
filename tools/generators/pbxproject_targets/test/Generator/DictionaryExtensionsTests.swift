import GeneratorCommon
import XCTest

@testable import pbxproject_targets

final class DictionaryExtensionsTests: XCTestCase {
    func test_valueForKeyContext_valid() throws {
        // Arrange

        let dict: [String: Int] = [
            "Hello": 42,
            "World": 7,
        ]
        
        let expectedValue = 42

        // Act

        let value = try dict.value(for: "Hello", context: "The string")

        // Assert

        XCTAssertEqual(value, expectedValue)
    }

    func test_valueForKeyContext_invalid() throws {
        // Arrange

        let dict: [String: Int] = [
            "Hello": 42,
            "World": 7,
        ]

        let expectedErrorMessage = """
The string "Bazel" not found in:
["Hello", "World"]
"""

        do {
            // Act

            _ = try dict.value(for: "Bazel", context: "The string")

            XCTFail("Expected to throw")
        } catch let error as PreconditionError {
            // Assert

            XCTAssertEqual(error.message, expectedErrorMessage)
        }
    }
}
