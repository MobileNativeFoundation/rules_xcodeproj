import CustomDump
import XCTest

@testable import generator

final class DisambiguateTargetsTests: XCTestCase {
    func test_label() throws {
        // Arrange
        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                label: "//a:A",
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                label: "//b:A",
                product: .init(type: .application, name: "A", path: "")
            ),
            "A 3": Target.mock(
                label: "//b:A",
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                label: "//a:B",
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            // The following targets only differ by case
            "C 1": Target.mock(
                label: "//c:A",
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "C 2": Target.mock(
                label: "//c:a",
                product: .init(type: .application, name: "a", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "//a:A",
            "A 2": "//b:A (App)",
            "A 3": "//b:A (Library)",
            "B": "B",
            "C 1": "//c:A (Library)",
            "C 2": "//c:a (App)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

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
            // The following targets only differ by case
            "C 1": Target.mock(
                product: .init(type: .staticLibrary, name: "C", path: "")
            ),
            "C 2": Target.mock(
                product: .init(type: .application, name: "c", path: "")
            ),
        ]
        let expectedTargetNames: [TargetID: String] = [
            "A 1": "A (Library)",
            "A 2": "A (App)",
            "B": "B",
            "C 1": "C (Library)",
            "C 2": "c (App)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(targets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_productType_sameName() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(os: .iOS),
                product: .init(type: .application, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .device(os: .watchOS),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_architecture() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .macOS(arch: "arm64"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .macOS(arch: "x86_64"),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_minimumOS() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(minimumOsVersion: "15.1"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .device(minimumOsVersion: "13.2"),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_environment() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .simulator(),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_operatingSystem() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(arch: "arm64", minimumOsVersion: "15.1"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .macOS(arch: "x86_64", minimumOsVersion: "12.0"),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_productTypeAndOperatingSystem() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .macOS(),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                platform: .macOS(),
                product: .init(type: .application, name: "A", path: "")
            ),
            "B": Target.mock(
                platform: .macOS(),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_configuration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                configuration: "1",
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                configuration: "2",
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_productTypeAndConfiguration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                configuration: "1",
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                configuration: "2",
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                configuration: "2",
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }

    func test_operatingSystemAndConfiguration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                configuration: "1",
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                configuration: "2",
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                configuration: "2",
                platform: .macOS(),
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
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            targets
        )
    }
}
