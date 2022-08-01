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

    func test_orThrow_noValue() throws {
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
}
