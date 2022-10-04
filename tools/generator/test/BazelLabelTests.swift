import XCTest

@testable import generator

class BazelLabelTests: XCTestCase {
    func test_init_withStringLiteral_noRepository() throws {
        let label: BazelLabel = "@//foo/bar:hello"
        XCTAssertEqual(label.repository, "@")
        XCTAssertEqual(label.package, "foo/bar")
        XCTAssertEqual(label.name, "hello")
    }

    func test_init_withStringLiteral_withRepository() throws {
        let label: BazelLabel = "@awesome_repo//foo/bar:hello"
        XCTAssertEqual(label.repository, "@awesome_repo")
        XCTAssertEqual(label.package, "foo/bar")
        XCTAssertEqual(label.name, "hello")
    }

    func test_init_withStringLiteral_noName() throws {
        let label: BazelLabel = "@//foo/bar"
        XCTAssertEqual(label.repository, "@")
        XCTAssertEqual(label.package, "foo/bar")
        XCTAssertEqual(label.name, "bar")
    }

    func test_customString_withRepository() throws {
        let label: BazelLabel = "@awesome_repo//foo/bar:hello"
        let actual = "\(label)"
        XCTAssertEqual("@awesome_repo//foo/bar:hello", actual)
    }

    func test_customString_noRepository() throws {
        let label: BazelLabel = "@//foo/bar:hello"
        let actual = "\(label)"
        XCTAssertEqual("@//foo/bar:hello", actual)
    }

    func test_customString_noName() throws {
        let label: BazelLabel = "@//foo/bar"
        let actual = "\(label)"
        XCTAssertEqual("@//foo/bar:bar", actual)
    }

    func test_encodingAndDecoding() throws {
        let label: BazelLabel = "@//foo/bar:hello"

        let encoder = JSONEncoder()
        let data = try encoder.encode(label)
        let dataStr = String(data: data, encoding: .utf8)!
        XCTAssertEqual(dataStr, "\"@\\/\\/foo\\/bar:hello\"")

        let decoder = JSONDecoder()
        let result = try decoder.decode(BazelLabel.self, from: data)
        XCTAssertEqual(label, result)
    }

    func assertParseError(
        value: String,
        expectedError: BazelLabel.ParseError,
        file: StaticString = #file, line: UInt = #line
    ) {
        var thrownError: Error?
        XCTAssertThrowsError(try BazelLabel(value), file: file, line: line) {
            thrownError = $0
        }
        XCTAssertEqual(
            thrownError as? BazelLabel.ParseError,
            expectedError,
            file: file, line: line
        )
    }

    func test_init_withInvalidValues() throws {
        assertParseError(
            value: ":hello",
            expectedError: .missingOrTooManyRootSeparators
        )
        assertParseError(
            value: "//howdy//:hello",
            expectedError: .missingOrTooManyRootSeparators
        )
        assertParseError(
            value: "//",
            expectedError: .missingNameAndPackage
        )
        assertParseError(
            value: "@//foo:hello:bar",
            expectedError: .tooManyColons
        )
    }
}
