import XCTest

@testable import generator

extension DictionaryExtensionTests {
    func test_value_keyExists() throws {
        let actual = try targetIDsByLabel.value(for: labelA)
        XCTAssertEqual(actual, targetA)
    }

    func test_value_keyDoesNotExist_noContext() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try targetIDsByLabel.value(for: "//:does_not_exist")
        ) {
            thrown = $0
        }
        guard let error = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`.")
            return
        }
        XCTAssertEqual(error.message, """
Unable to find the `TargetID` for the `BazelLabel`, "//:does_not_exist".
""")
    }

    func test_value_keyDoesNotExist_withContext() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try targetIDsByLabel.value(
                for: "//:does_not_exist",
                context: "performing a test"
            )
        ) {
            thrown = $0
        }
        guard let error = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`.")
            return
        }
        XCTAssertEqual(error.message, """
Unable to find the `TargetID` for the `BazelLabel`, "//:does_not_exist", while performing a test.
""")
    }

    func test_value_keyDoesNotExist_withMessage() throws {
        let customErrorMessage = "Custom error message."
        var thrown: Error?
        XCTAssertThrowsError(
            try targetIDsByLabel.value(for: "//:does_not_exist", message: customErrorMessage)
        ) {
            thrown = $0
        }
        guard let error = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`.")
            return
        }
        XCTAssertEqual(error.message, customErrorMessage)
    }
}

class DictionaryExtensionTests: XCTestCase {
    let labelA: BazelLabel = "//:A"
    let targetA: TargetID = "targetA"

    lazy var targetIDsByLabel: [BazelLabel: TargetID] = [labelA: targetA]
}
