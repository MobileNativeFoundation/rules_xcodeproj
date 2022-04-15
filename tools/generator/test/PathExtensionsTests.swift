import PathKit
import XCTest

@testable import generator

final class PathExtensionsTests: XCTestCase {
    func test_is_bazel_build_file() {
        XCTAssertFalse(("/foo" as Path).isBazelBuildFile)
        XCTAssertFalse(("/ABUILD" as Path).isBazelBuildFile)
        XCTAssertTrue(("/BUILD.bazel" as Path).isBazelBuildFile)
        XCTAssertTrue(("/BUILD" as Path).isBazelBuildFile)
        XCTAssertTrue(("/foo/BUILD" as Path).isBazelBuildFile)
    }

    func test_explicit_file_type() {
        XCTAssertNil(("/foo" as Path).explicitFileType)
        XCTAssertNil(("/ABUILD" as Path).explicitFileType)
        XCTAssertEqual(("/BUILD.bazel" as Path).explicitFileType, "text.script.python")
        XCTAssertEqual(("/BUILD" as Path).explicitFileType, "text.script.python")
        XCTAssertEqual(("/foo/BUILD" as Path).explicitFileType, "text.script.python")
    }
}
