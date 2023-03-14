import XCTest

@testable import generator

extension DictionaryExtensionTests {
    func test_value_keyExists() throws {
        let actual = try targetIDsByLabelAndConfiguration.value(for: labelA)
        XCTAssertEqual(actual, targetA)
    }

    func test_value_keyDoesNotExist_noContext() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try targetIDsByLabelAndConfiguration.value(for: "@//:does_not_exist")
        ) {
            thrown = $0
        }
        guard let error = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`.")
            return
        }
        let expectedMainMsg = """
Unable to find the `TargetID` for the `BazelLabel`, "@//:does_not_exist".
"""
        XCTAssertTrue(error.message.contains(expectedMainMsg))
        let expectedPostMsgFragment = """
function: test_value_keyDoesNotExist_noContext()
"""
        XCTAssertTrue(error.message.contains(expectedPostMsgFragment))
    }

    func test_value_keyDoesNotExist_withContext() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try targetIDsByLabelAndConfiguration.value(
                for: "@//:does_not_exist",
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
Unable to find the `TargetID` for the `BazelLabel`, "@//:does_not_exist", \
while performing a test.
""")
    }

    func test_value_keyDoesNotExist_withMessage() throws {
        let customErrorMessage = "Custom error message."
        var thrown: Error?
        XCTAssertThrowsError(
            try targetIDsByLabelAndConfiguration.value(
                for: "@//:does_not_exist",
                message: customErrorMessage
            )
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
    let labelA: BazelLabel = "@//:A"
    let targetA: TargetID = "targetA"

    lazy var targetIDsByLabelAndConfiguration: [BazelLabel: TargetID] = [labelA: targetA]
}
