import XCTest

@testable import generator

// MARK: `compatibility` Tests

extension PlatformExtensionsTests {
    func test_compatibility_osMismatch() throws {
        let platform = Platform.device(os: .tvOS)
        XCTAssertEqual(platform.compatibility(with: other), .osNotEqual)
    }

    func test_compatibility_variantMismatch() throws {
        let platform = Platform(
            os: other.os,
            variant: .tvOSDevice,
            arch: other.arch,
            minimumOsVersion: other.minimumOsVersion
        )
        XCTAssertEqual(platform.compatibility(with: other), .variantNotEqual)
    }

    func test_compatibility_archMismatch() throws {
        let platform = Platform.device(os: .iOS, arch: "x86_64")
        XCTAssertEqual(platform.compatibility(with: other), .archNotEqual)
    }

    func test_compatibility_minOsGreaterThan() throws {
        let platform = Platform.device(os: .iOS, minimumOsVersion: "12.0")
        XCTAssertEqual(platform.compatibility(with: other), .minimumOsVersionGreaterThanOther)
    }

    func test_compatibility_minOsEqual() throws {
        let platform = other
        XCTAssertEqual(platform.compatibility(with: other), .compatible)
    }

    func test_compatibility_minOsLessThan() throws {
        let platform = Platform.device(os: .iOS, minimumOsVersion: "10.0")
        XCTAssertEqual(platform.compatibility(with: other), .compatible)
    }

    func test_compatibility_selfNoMinOsVer() throws {
        let platform = Platform.device(os: .iOS, minimumOsVersion: "unrecognizable")
        XCTAssertEqual(platform.compatibility(with: other), .noMinimumOsSemanticVersionForSelf)
    }

    func test_compatibility_otherNoMinOsVer() throws {
        let platform = Platform.device(os: .iOS)
        let other = Platform.device(os: .iOS, minimumOsVersion: "unrecognizable")
        XCTAssertEqual(platform.compatibility(with: other), .noMinimumOsSemanticVersionForOther)
    }
}

// MARK: `isCompatible` Tests

extension PlatformExtensionsTests {
    func test_Compatibility_isCompatible_compatible() throws {
        XCTAssertTrue(Platform.Compatibility.compatible.isCompatible)
    }

    func test_Compatibility_isCompatible_notCompatible() throws {
        XCTAssertFalse(Platform.Compatibility.osNotEqual.isCompatible)
    }
}

extension PlatformExtensionsTests {
    func test_compatibleWith_compatible() throws {
        let platforms: [Platform] = [.macOS(), other]
        let platform = other
        XCTAssertTrue(platform.compatibleWith(anyOf: platforms))
    }

    func test_compatibleWith_notCompatible() throws {
        let platforms: [Platform] = [.macOS(), .device(os: .tvOS)]
        let platform = other
        XCTAssertFalse(platform.compatibleWith(anyOf: platforms))
    }
}

class PlatformExtensionsTests: XCTestCase {
    let other = Platform.device(os: .iOS)
}
