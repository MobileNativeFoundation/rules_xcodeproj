import CustomDump
import XCTest

@testable import generator

final class DisambiguateTargetsTests: XCTestCase {
    func test_productType() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                product: .init(type: .application, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (Library)",
            "A 2": "A (App)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_productType_sameName() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.0",
                    environment: nil
                ),
                product: .init(type: .application, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .init(
                    os: .watchOS,
                    arch: "arm64",
                    minimumOsVersion: "8.0",
                    environment: nil
                ),
                product: .init(type: .watch2App, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (iOS)",
            "A 2": "A (watchOS)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_architecture() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .init(
                    os: .macOS,
                    arch: "arm64",
                    minimumOsVersion: "12.0",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .init(
                    os: .macOS,
                    arch: "x86_64",
                    minimumOsVersion: "12.0",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (arm64)",
            "A 2": "A (x86_64)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_minimumOS() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "13.2",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (iOS 15.1)",
            "A 2": "A (iOS 13.2)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_environment() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: "Simulator"
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (Device)",
            "A 2": "A (Simulator)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_operatingSystem() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .init(
                    os: .macOS,
                    arch: "x86_64",
                    minimumOsVersion: "12.0",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (iOS)",
            "A 2": "A (macOS)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_productTypeAndOperatingSystem() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .init(
                    os: .macOS,
                    arch: "arm64",
                    minimumOsVersion: "11.2",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                platform: .init(
                    os: .macOS,
                    arch: "arm64",
                    minimumOsVersion: "11.2",
                    environment: nil
                ),
                product: .init(type: .application, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (Library) (iOS)",
            "A 2": "A (Library) (macOS)",
            "A 3": "A (App)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_configuration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                configuration: "1",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                configuration: "2",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (\(Target.prettyConfiguration("1")))",
            "A 2": "A (\(Target.prettyConfiguration("2")))",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_productTypeAndConfiguration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                configuration: "1",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                configuration: "2",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                configuration: "2",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .application, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (Library) (\(Target.prettyConfiguration("1")))",
            "A 2": "A (Library) (\(Target.prettyConfiguration("2")))",
            "A 3": "A (App)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }

    func test_operatingSystemAndConfiguration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                configuration: "1",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                configuration: "2",
                platform: .init(
                    os: .iOS,
                    arch: "arm64",
                    minimumOsVersion: "15.1",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                configuration: "2",
                platform: .init(
                    os: .macOS,
                    arch: "arm64",
                    minimumOsVersion: "12.0",
                    environment: nil
                ),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (iOS, \(Target.prettyConfiguration("1")))",
            "A 2": "A (iOS, \(Target.prettyConfiguration("2")))",
            "A 3": "A (macOS)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.mapValues(\.target),
            targets
        )
    }
}
