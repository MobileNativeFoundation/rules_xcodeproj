import GeneratorCommon
import XCTest

@testable import pbxproject_prefix

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

    func test_tooLargeXcode() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "42.3.1"
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
}

extension SemanticVersion: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(extendedGraphemeClusterLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(unicodeScalarLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(version: value)!
    }
}
