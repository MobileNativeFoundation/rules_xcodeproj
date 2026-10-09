import CustomDump
import PBXProj
import XCTest

final class BazelPathSynchronizedFoldersTests: XCTestCase {
    func test_removingPaths() {
        // Arrange

        let paths: [BazelPath] = [
            "a/BUILD",
            "a/Sources",
            "a/Sources/A.swift",
            "a/Sources/Nested/B.swift",
            "a/SourcesOther/C.swift",
            "b/Sources/D.swift",
            "",
        ]
        let expectedPaths: [BazelPath] = [
            "a/BUILD",
            "a/Sources",
            "a/SourcesOther/C.swift",
            "b/Sources/D.swift",
            "",
        ]

        // Act

        let result = paths.removingPaths(inSynchronizedFolders: ["a/Sources"])

        // Assert

        XCTAssertNoDifference(result, expectedPaths)
    }

    func test_removingPaths_noFolders() {
        let paths: [BazelPath] = ["a/Sources/A.swift"]

        XCTAssertNoDifference(
            paths.removingPaths(inSynchronizedFolders: []),
            paths
        )
    }
}
