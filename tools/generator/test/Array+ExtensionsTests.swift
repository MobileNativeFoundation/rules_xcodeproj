import XCTest

@testable import generator

final class ArrayExtenstionsTests: XCTestCase {
    func test_extractCommandLineArguments() {
        let result: [String] = [
            "--command_line_args=-AppleLanguages,(en)",
            "--someOtherFlag",
        ].extractCommandLineArguments()
        XCTAssertEqual(result, ["-AppleLanguages", "(en)"])
    }
}
