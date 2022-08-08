import XCTest

@testable import generator

extension XcodeSchemeTests {
    func test_BuildAction_init_noDuplicateLabels() throws {
        let buildTarget = try XcodeScheme.BuildAction(
            targets: [.init(label: "//foo"), .init(label: "//bar")]
        )
        XCTAssertEqual(buildTarget.targets.count, 2)
    }

    func test_BuildAction_init_withDuplicateLabels() throws {
        var thrown: Error?
        XCTAssertThrowsError(
            try XcodeScheme.BuildAction(
                targets: [.init(label: "//foo"), .init(label: "//foo")]
            )
        ) {
            thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected `PreconditionError`.")
            return
        }
        XCTAssertEqual(preconditionError.message, """
Found a duplicate label //foo:foo in provided `XcodeScheme.BuildTarget` values.
""")
    }
}

class XcodeSchemeTests: XCTestCase {}
