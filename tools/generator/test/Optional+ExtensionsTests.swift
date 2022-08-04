import XCTest

@testable import generator

class OptionalExtensionTests: XCTestCase {
    let errorMessage = "No value."

    func test_orThrow_withValue() throws {
        let expected = "Foo"
        let opt: String? = expected
        let actual = try opt.orThrow(errorMessage)
        XCTAssertEqual(actual, expected)
    }

    func test_orThrow_noValue_withErrorMessage() throws {
        let opt: String? = nil
        var thrown: Error?
        XCTAssertThrowsError(try opt.orThrow(errorMessage)) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`.")
            return
        }
        XCTAssertEqual(preconditionError.message, errorMessage)
    }

    func test_orThrow_noValue_noErrorMessage() throws {
        let opt: String? = nil
        var thrown: Error?
        XCTAssertThrowsError(try opt.orThrow()) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected a `PreconditionError`.")
            return
        }
        let expectedMsgFragment = """
Expected non-nil value. (function: \(#function),
"""
        XCTAssertTrue(preconditionError.message.contains(expectedMsgFragment))
    }
}
