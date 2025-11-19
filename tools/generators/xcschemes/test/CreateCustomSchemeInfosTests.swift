import XCTest

@testable import xcschemes

final class CreateCustomSchemeInfosTests: XCTestCase {
    func test_url_relativize() {
        typealias TestCase = (dest: URL, source: URL, expected: String?)
        let testCases: [TestCase] = [
            // Common root
            (URL(filePath: "/path/to/my/file.txt"), URL(filePath: "/path/to/your/dir"), "../my/file.txt"),
            // No common root
            (URL(filePath: "/path/to/my/file.txt"), URL(filePath: "/home/from/your/dir"), "../../../path/to/my/file.txt"),
            // Both empty paths (implied to be /private/tmp in Bazel)
            (URL(filePath: ""), URL(filePath: ""), "/private/tmp"),
            // Empty destination path, absolute source path
            (URL(filePath: ""), URL(filePath: "/path"), "private/tmp"),
            // Absolute destination path, empty source path
            (URL(filePath: "/path"), URL(filePath: ""), "../path"),
            // Relative destination path (implied to be relative to /private/tmp in Bazel), absolute source path
            (URL(filePath: "path/to/file.txt"), URL(filePath: "/path/to/dir"), "../../private/tmp/path/to/file.txt"),
            // Absolute destination path, relative source path
            (URL(filePath: "/path/to/file.txt"), URL(filePath: "path/to/dir"), "../../../../path/to/file.txt"),
            // Weird relative destination path
            (URL(filePath: "../../file.txt"), URL(filePath: "/path/to/dir"), "../../file.txt"),
            // Absolute destination path, weird relative source path
            (URL(filePath: "/path/to/file.txt"), URL(filePath: "../../to/dir"), "../path/to/file.txt"),
        ]
        for (dest, source, expected) in testCases {
            let actual = dest.relativize(from: source)
            XCTAssertEqual(expected, actual)
        }
    }
}
