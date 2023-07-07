import GeneratorCommon
import XCTest

@testable import pbxproj_prefix

class CompatibilityVersionTests: XCTestCase {
    func test_lowXcodeVersion() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "11.4.7"
        let expectedCompatibilityVersion = "Xcode 11.0"

        // Act

        let compatibilityVersion = Generator.compatibilityVersion(
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertEqual(
            compatibilityVersion,
            expectedCompatibilityVersion
        )
    }

    func test_xcode13() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "13.4.2"
        let expectedCompatibilityVersion = "Xcode 13.0"

        // Act

        let compatibilityVersion = Generator.compatibilityVersion(
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertEqual(
            compatibilityVersion,
            expectedCompatibilityVersion
        )
    }

    func test_xcode14() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "14.2.1"
        let expectedCompatibilityVersion = "Xcode 14.0"

        // Act

        let compatibilityVersion = Generator.compatibilityVersion(
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertEqual(
            compatibilityVersion,
            expectedCompatibilityVersion
        )
    }

    func test_xcode15() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "15.0.1"
        let expectedCompatibilityVersion = "Xcode 15.0"

        // Act

        let compatibilityVersion = Generator.compatibilityVersion(
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertEqual(
            compatibilityVersion,
            expectedCompatibilityVersion
        )
    }

    func test_tooLargeXcode() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "42.3.1"
        let expectedCompatibilityVersion = "Xcode 15.0"

        // Act

        let compatibilityVersion = Generator.compatibilityVersion(
            minimumXcodeVersion: minimumXcodeVersion
        )

        // Assert

        XCTAssertEqual(
            compatibilityVersion,
            expectedCompatibilityVersion
        )
    }
}
