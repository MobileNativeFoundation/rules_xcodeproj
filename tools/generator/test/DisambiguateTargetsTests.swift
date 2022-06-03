import CustomDump
import XCTest

@testable import generator

final class DisambiguateTargetsTests: XCTestCase {

    // MARK: - Label

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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "//a:A",
            "A 2": "//b:A (App)",
            "A 3": "//b:A (Library)",
            "B": "B",
            "C 1": "//c:A (Library)",
            "C 2": "//c:a (App)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Product Type

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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (Library)",
            "A 2": "A (App)",
            "B": "B",
            "C 1": "C (Library)",
            "C 2": "c (App)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
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
                platform: .simulator(os: .watchOS),
                product: .init(type: .watch2App, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (iOS)",
            "A 2": "A (watchOS)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Architecture

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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (arm64)",
            "A 2": "A (x86_64)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Minimum OS Version

    func test_minimumOS() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(arch: "arm64", minimumOsVersion: "15.1"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .simulator(arch: "x86_64", minimumOsVersion: "13.2"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (iOS 15.1)",
            "A 2": "A (iOS 13.2)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Environment

    func test_environment() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(arch: "arm64"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .simulator(arch: "x86_64"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (Device)",
            "A 2": "A (Simulator)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Operating System

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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (iOS)",
            "A 2": "A (macOS)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (Library) (iOS)",
            "A 2": "A (Library) (macOS)",
            "A 3": "A (App)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Configuration

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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": "A (\(ProductTypeComponents.prettyConfigurations(["1"])))",
            "A 2": "A (\(ProductTypeComponents.prettyConfigurations(["2"])))",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": """
A (Library) (\(ProductTypeComponents.prettyConfigurations(["1"])))
""",
            "A 2": """
A (Library) (\(ProductTypeComponents.prettyConfigurations(["2"])))
""",
            "A 3": "A (App)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
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
        let consolidatedTargets = ConsolidatedTargets(targets: targets)
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            "A 1": """
A (iOS) (\(ProductTypeComponents.prettyConfigurations(["1"])))
""",
            "A 2": """
A (iOS) (\(ProductTypeComponents.prettyConfigurations(["2"])))
""",
            "A 3": "A (macOS)",
            "B": "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    // MARK: - Consolidated Targets

    func test_consolidated() throws {
        // Arrange
        let targets: [TargetID: Target] = [
            "iOS-Simulator": .mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "T", path: "IS/T")
            ),
            "iOS-Device": .mock(
                platform: .device(os: .iOS, minimumOsVersion: "11.3"),
                product: .init(type: .staticLibrary, name: "T", path: "ID/T")
            ),
            "watchOS-Simulator": .mock(
                platform: .simulator(os: .watchOS, minimumOsVersion: "7.0"),
                product: .init(type: .staticLibrary, name: "T", path: "WS/T")
            ),
            "watchOS-Device": .mock(
                platform: .device(os: .watchOS, minimumOsVersion: "7.2"),
                product: .init(type: .staticLibrary, name: "T", path: "WD/T")
            ),
            "tvOS-Simulator": .mock(
                platform: .simulator(os: .tvOS, minimumOsVersion: "9.0"),
                product: .init(type: .staticLibrary, name: "T", path: "TS/T")
            ),
            "tvOS-Device": .mock(
                platform: .device(os: .tvOS, minimumOsVersion: "9.1"),
                product: .init(type: .staticLibrary, name: "T", path: "TD/T")
            ),
            "macOS": .mock(
                platform: .macOS(minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "T", path: "M/T")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                [
                    "iOS-Simulator",
                    "iOS-Device",
                    "watchOS-Simulator",
                    "watchOS-Device",
                    "tvOS-Simulator",
                    "tvOS-Device",
                    "macOS",
                ],
            ]
        )
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            .init([
                "iOS-Simulator",
                "iOS-Device",
                "watchOS-Simulator",
                "watchOS-Device",
                "tvOS-Simulator",
                "tvOS-Device",
                "macOS",
            ]): "T",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    func test_consolidated_operatingSystem() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "15.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "15.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                platform: .device(os: .tvOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 4": Target.mock(
                platform: .device(os: .watchOS, minimumOsVersion: "9.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B 1": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "15.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 2": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "14.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 3": Target.mock(
                platform: .device(os: .tvOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A 1", "A 2", "A 3"],
                ["A 4"],
                ["B 1", "B 2", "B 3"],
            ]
        )
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            .init(["A 1", "A 2", "A 3"]): "A (iOS, tvOS)",
            "A 4": "A (watchOS)",
            .init(["B 1", "B 2", "B 3"]): "B",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    func test_consolidated_minimumOS() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "13.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                platform: .device(os: .tvOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 4": Target.mock(
                platform: .simulator(os: .tvOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B 1": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 2": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 3": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 4": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A 1", "A 3", "A 4"],
                ["A 2"],
                ["B 1", "B 2"],
                ["B 3", "B 4"],
            ]
        )
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            .init(["A 1", "A 3", "A 4"]): "A (iOS 11.0, tvOS)",
            "A 2": "A (iOS 13.0)",
            .init(["B 1", "B 2"]): "B (iOS 11.0)",
            .init(["B 3", "B 4"]): "B (iOS 12.0)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    func test_consolidated_minimumOSAndEnvironment() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A 1": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 2": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "13.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "A 3": Target.mock(
                platform: .device(os: .tvOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B 1": Target.mock(
                platform: .device(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 2": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "13.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 3": Target.mock(
                platform: .device(os: .tvOS, minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
            "B 4": Target.mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "14.0"),
                product: .init(type: .staticLibrary, name: "B", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A 1", "A 2", "A 3"],
                ["B 1", "B 2", "B 3"],
                ["B 4"],
            ]
        )
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            .init(["A 1", "A 2", "A 3"]): "A",
            .init(["B 1", "B 2", "B 3"]): """
B (iOS 13.0 Simulator, iOS 11.0 Device, tvOS)
""",
            "B 4": "B (iOS 14.0)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    func test_consolidated_environment() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A": Target.mock(
                platform: .device(os: .iOS),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                platform: .simulator(os: .iOS),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "C": Target.mock(
                platform: .device(os: .tvOS),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A", "C"],
                ["B"],
            ]
        )
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            .init(["A", "C"]): "A (iOS Device, tvOS)",
            "B": "A (iOS Simulator)",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }

    func test_consolidated_operatingSystemAndConfiguration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A": Target.mock(
                configuration: "1",
                platform: .device(os: .iOS),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "B": Target.mock(
                configuration: "2",
                platform: .device(os: .iOS),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
            "C": Target.mock(
                configuration: "3",
                platform: .device(os: .tvOS),
                product: .init(type: .staticLibrary, name: "A", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A", "C"],
                ["B"],
            ]
        )
        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            .init(["A", "C"]): """
A (iOS, tvOS) (\(ProductTypeComponents.prettyConfigurations(["1", "3"])))
""",
            "B": """
A (iOS) (\(ProductTypeComponents.prettyConfigurations(["2"])))
""",
        ]

        // Act

        let disambiguatedTargets = Generator.disambiguateTargets(
            consolidatedTargets
        )

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.name),
            expectedTargetNames
        )
        XCTAssertNoDifference(
            disambiguatedTargets.targets.mapValues(\.target),
            consolidatedTargets.targets
        )
    }
}
