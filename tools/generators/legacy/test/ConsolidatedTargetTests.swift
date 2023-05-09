import CustomDump
import XCTest

@testable import generator

final class ConsolidatedTargetTests: XCTestCase {
    static let targets: [TargetID: Target] = [
        "A": Target.mock(
            platform: .simulator(),
            product: .init(type: .staticLibrary, name: "T", path: "A"),
            inputs: .init(
                srcs: ["a", "0", "-"],
                nonArcSrcs: ["aa"],
                hdrs: ["123"],
                resources: ["bbb"]
            ),
            linkerInputs: .init(
                dynamicFrameworks: ["yy"]
            )
        ),
        "B": Target.mock(
            platform: .device(),
            product: .init(type: .staticLibrary, name: "T", path: "B"),
            inputs: .init(
                srcs: ["a", "1", "-"],
                nonArcSrcs: ["aa", "cc"],
                hdrs: ["456"],
                resources: ["aaa", "bbb"]
            ),
            linkerInputs: .init(
                dynamicFrameworks: ["xx", "yy"]
            )
        ),
        "C": Target.mock(
            platform: .macOS(),
            product: .init(type: .staticLibrary, name: "T", path: "C"),
            inputs: .init(
                srcs: ["a", "2", "-"],
                nonArcSrcs: ["aa", "bb"],
                hdrs: ["789"],
                resources: ["ccc", "bbb"]
            ),
            linkerInputs: .init(
                dynamicFrameworks: ["yy", "zz"]
            )
        ),
    ]

    func test_inputs() {
        // Arrange

        let targets = Self.targets
        let expectedInputs = ConsolidatedTargetInputs(
            // Conditionals in middle
            srcs: ["a", "1", "0", "2", "-"],
            // Conditionals at the end
            nonArcSrcs: ["aa", "cc", "bb"],
            hdrs: ["123", "456", "789"],
            // Conditionals at the start
            resources: ["aaa", "ccc", "bbb"]
        )

        // Act

        let consolidatedTarget = ConsolidatedTarget(targets: targets)

        // Assert

        XCTAssertNoDifference(consolidatedTarget.inputs, expectedInputs)
    }

    func test_linkerInputs() {
        // Arrange

        let targets = Self.targets
        let expectedLinkerInputs = ConsolidatedTargetLinkerInputs(
            // Conditionals on the outsides
            dynamicFrameworks: ["xx", "yy", "zz"]
        )

        // Act

        let consolidatedTarget = ConsolidatedTarget(targets: targets)

        // Assert

        XCTAssertNoDifference(
            consolidatedTarget.linkerInputs,
            expectedLinkerInputs
        )
    }

    func test_uniqueFiles_xcode() {
        // Arrange

        let targets = Self.targets
        let expectedUniqueFiles: [TargetID: Set<FilePath>] = [
            "A": ["0", "123"],
            "B": ["1", "456", "cc", "aaa", "xx"],
            "C": ["2", "789", "bb", "ccc", "zz"],
        ]

        // Act

        let consolidatedTarget = ConsolidatedTarget(
            targets: targets,
            // Non-empty `xcodeGeneratedFiles` -> `buildMode == .xcode`
            xcodeGeneratedFiles: ["": ""]
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTarget.uniqueFiles,
            expectedUniqueFiles
        )
    }

    func test_uniqueFiles_bazel() {
        // Arrange

        let targets = Self.targets
        let expectedUniqueFiles: [TargetID: Set<FilePath>] = [
            "A": ["0", "123"],
            "B": ["1", "456", "cc"],
            "C": ["2", "789", "bb"],
        ]

        // Act

        let consolidatedTarget = ConsolidatedTarget(
            targets: targets,
            // Empty `xcodeGeneratedFiles` -> `buildMode == .bazel`
            xcodeGeneratedFiles: [:]
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTarget.uniqueFiles,
            expectedUniqueFiles
        )
    }
}
