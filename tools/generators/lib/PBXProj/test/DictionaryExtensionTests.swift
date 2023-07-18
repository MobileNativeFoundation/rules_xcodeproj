import GeneratorCommon
import PBXProj
import XCTest

final class DictionaryExtensionTests: XCTestCase {

    // MARK: - update()

    func test_update() {
        // Arrange

        var dict: [String: Int] = [
            "Hello": 42,
            "World": 7,
        ]
        let updateDict: [String: Int] = [
            "Bye": 1,
            "World": 56,
        ]

        let expectedDict: [String: Int] = [
            "Bye": 1,
            "Hello": 42,
            "World": 56,
        ]

        // Act

        dict.update(updateDict)

        // Assert

        XCTAssertEqual(dict, expectedDict)
    }

    // MARK: - updating()

    func test_updating() {
        // Arrange

        let dict: [String: Int] = [
            "Hello": 42,
            "World": 7,
        ]
        let updateDict: [String: Int] = [
            "Bye": 1,
            "World": 56,
        ]

        let expectedUpdatedDict: [String: Int] = [
            "Bye": 1,
            "Hello": 42,
            "World": 56,
        ]

        // Act

        let updatedDict = dict.updating(updateDict)

        // Assert

        XCTAssertEqual(updatedDict, expectedUpdatedDict)
    }

    // MARK: - value(for:context:)

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
