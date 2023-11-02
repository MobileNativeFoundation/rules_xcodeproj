import CustomDump
import OrderedCollections
import XCTest

@testable import PBXProj

final class TargetSwiftDebugSettingsTests: XCTestCase {
    func test_encodeDecode() async throws {
        // Arrange

        let clangArgs = [
            "-v",
            "abdc efg",
            "something\nwith\nnewlines",
        ]
        let frameworkIncludes: OrderedSet<String> = [
            "a/path",
            "some path/some/where",
            "a\npath/with\nnewlines",
        ]
        let swiftIncludes: OrderedSet<String> = [
            "swift/module",
            "some swift/module/path",
            "a\nswift/module\nnewlines",
        ]

        let expected = TargetSwiftDebugSettings(
            clangArgs: clangArgs,
            frameworkIncludes: frameworkIncludes.elements,
            swiftIncludes: swiftIncludes.elements
        )

        let tempDir = try TemporaryDirectory()
        let file = tempDir.url.appendingPathComponent("tmp", isDirectory: false)

        // Act

        try WriteTargetSwiftDebugSettings.defaultCallable(
            clangArgs: clangArgs,
            frameworkIncludes: frameworkIncludes,
            swiftIncludes: swiftIncludes,
            to: file
        )
        let result = try await ReadTargetSwiftDebugSettingsFile.defaultCallable(
            url: file
        )

        // Assert

        XCTAssertNoDifference(result, expected)
    }
}
