import XCTest

@testable import generator

// MARK: `compatibility` Tests

extension PlatformExtensionsTests {
    func test_compatibility_osMismatch() throws {
        let platform = Platform.device(os: .tvOS)
        XCTAssertEqual(platform.compatibility(with: iOSarm64Platform), .osNotEqual)
    }

    func test_compatibility_variantMismatch() throws {
        let platform = Platform(
            os: iOSarm64Platform.os,
            variant: .iOSSimulator,
            arch: iOSarm64Platform.arch,
            minimumOsVersion: iOSarm64Platform.minimumOsVersion
        )
        XCTAssertEqual(platform.compatibility(with: iOSarm64Platform), .variantNotEqual)
    }

    func test_compatibility_archMismatch() throws {
        XCTAssertEqual(iOSx8664Platform.compatibility(with: iOSarm64Platform), .archNotEqual)
    }

    func test_compatibility_minOsGreaterThan() throws {
        let platform = Platform.device(os: .iOS, minimumOsVersion: "12.0")
        XCTAssertEqual(platform.compatibility(with: iOSarm64Platform), .minimumOsVersionGreaterThanOther)
    }

    func test_compatibility_minOsEqual() throws {
        let platform = iOSarm64Platform
        XCTAssertEqual(platform.compatibility(with: iOSarm64Platform), .compatible)
    }

    func test_compatibility_minOsLessThan() throws {
        let platform = Platform.device(os: .iOS, minimumOsVersion: "10.0")
        XCTAssertEqual(platform.compatibility(with: iOSarm64Platform), .compatible)
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

// MARK: `compatibleWith(anyOf:)` Tests

extension PlatformExtensionsTests {
    func test_compatibleWith_compatible() throws {
        let platforms: [Platform] = [.macOS(), iOSarm64Platform]
        let platform = iOSarm64Platform
        XCTAssertTrue(platform.compatibleWith(anyOf: platforms))
    }

    func test_compatibleWith_notCompatible() throws {
        let platforms: [Platform] = [.macOS(), .device(os: .tvOS)]
        let platform = iOSarm64Platform
        XCTAssertFalse(platform.compatibleWith(anyOf: platforms))
    }
}

// MARK: `compatibilityWith()` Tests

extension PlatformExtensionsTests {
    func test_Sequence_compatibleWith_noPlatforms() throws {
        let platforms = [Platform]()
        XCTAssertFalse(platforms.compatibleWith(iOSarm64Platform))
    }

    func test_Sequence_compatibleWith_isCompatible() throws {
        let platforms = [iOSarm64Platform, iOSx8664Platform]
        XCTAssertTrue(platforms.compatibleWith(iOSarm64Platform))
    }

    func test_Sequence_compatibleWith_isNotCompatible() throws {
        let platforms = [iOSx8664Platform]
        XCTAssertFalse(platforms.compatibleWith(iOSarm64Platform))
    }
}

class PlatformExtensionsTests: XCTestCase {
    let iOSarm64Platform = Platform.device(os: .iOS)
    let iOSx8664Platform = Platform.device(os: .iOS, arch: "x86_64")
}
