import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import files_and_groups

class ResolvedRepositoriesBuildSettingTests: XCTestCase {
    func test_sortedByResolvedPath() {
        // Arrange

        let resolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: ".", mappedPath: "/tmp/workspace"),
            .init(sourcePath: "./external/b", mappedPath: "/z/b/c"),
            .init(sourcePath: "./external/a/b", mappedPath: "/ex/a/b"),
            .init(sourcePath: "./external/c", mappedPath: "/z/b"),
        ]

        let expectedResolvedRepositoriesBuildSetting = """
"." "/tmp/workspace" "./external/a/b" "/ex/a/b" "./external/b" "/z/b/c" "./external/c" "/z/b"
"""

        // Act

        let resolvedRepositoriesBuildSetting = Generator
            .resolvedRepositoriesBuildSetting(
                resolvedRepositories: resolvedRepositories
            )

        // Assert

        XCTAssertNoDifference(
            resolvedRepositoriesBuildSetting,
            expectedResolvedRepositoriesBuildSetting
		)
    }
}
