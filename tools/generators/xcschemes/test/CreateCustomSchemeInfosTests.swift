import PBXProj
import XCScheme
import XCTest

@testable import xcschemes

final class CreateCustomSchemeInfosTests: XCTestCase {
    func test_merging_environment_variables() throws {
        let targets: [SchemeInfo.TestTarget] = [
            .init(
                target: .init(
                    key: .init([.init("target1")]),
                    productType: .unitTestBundle,
                    buildableReference: .init(
                        blueprintIdentifier: "",
                        buildableName: "",
                        blueprintName: "",
                        referencedContainer: "",
                    )
                ),
                isEnabled: true
            ),
            .init(
                target: .init(
                    key: .init([.init("target2")]),
                    productType: .unitTestBundle,
                    buildableReference: .init(
                        blueprintIdentifier: "",
                        buildableName: "",
                        blueprintName: "",
                        referencedContainer: "",
                    )
                ),
                isEnabled: true
            ),
        ]

        // No environment variables
        try XCTAssert(mergingEnvironmentVariables([:], in: []).isEmpty)

        // Environment variables with no overlap
        try XCTAssertEqual(
            mergingEnvironmentVariables(
                [
                    "target1": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                    "target2": [EnvironmentVariable(key: "VAR2", value: "value2", isEnabled: true)],
                ],
                in: targets
            ),
            [
                EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true),
                EnvironmentVariable(key: "VAR2", value: "value2", isEnabled: true),
            ]
        )

        // Environment variables with overlap (target1 and target2 both have VAR1, and the output should contain VAR1 because the values match.
        try XCTAssertEqual(
            mergingEnvironmentVariables(
                [
                    "target1": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                    "target2": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                ],
                in: targets
            ),
            [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)]
        )

        // Environment variables with overlap but different values (target1 and target2 both have VAR1, but the values differ, so the output should be empty because there is no consistent value for VAR1).
        try XCTAssertThrowsError(
            mergingEnvironmentVariables(
                [
                    "target1": [EnvironmentVariable(key: "VAR1", value: "value1", isEnabled: true)],
                    "target2": [EnvironmentVariable(key: "VAR1", value: "value2", isEnabled: true)],
                ],
                in: targets
            )
        )
    }

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
