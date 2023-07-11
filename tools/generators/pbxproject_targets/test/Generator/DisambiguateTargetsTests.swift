import CustomDump
import PBXProj
import XCTest

@testable import pbxproject_targets

final class DisambiguateTargetsTests: XCTestCase {
    // MARK: - Sorted

    func test_sorted() throws {
        // Arrange
        let targets: [Target] = [
            .mock(
                id: "A 1",
                label: "@//a:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "A 2",
                label: "@//b:A",
                productType: .application
            ),
            .mock(
                id: "A 3",
                label: "@//b:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "B",
                label: "@//a:B",
                productType: .staticLibrary
            ),
            // The following targets only differ by case
            .mock(
                id: "C 1",
                label: "@//c:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "C 2",
                label: "@//c:a",
                productType: .application
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [String] = [
            "@//a:A",
            "@//b:A (App)",
            "@//b:A (Library)",
            "@//c:a (App)",
            "@//c:A (Library)",
            "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets.map(\.name),
            expectedTargetNames
        )
    }

    // MARK: - Label

    func test_label() throws {
        // Arrange
        let targets: [Target] = [
            .mock(
                id: "A 1",
                label: "@//a:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "A 2",
                label: "@//b:A",
                productType: .application
            ),
            .mock(
                id: "A 3",
                label: "@//b:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "B",
                label: "@//a:B",
                productType: .staticLibrary
            ),
            // The following targets only differ by case
            .mock(
                id: "C 1",
                label: "@//c:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "C 2",
                label: "@//c:a",
                productType: .application
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A 1"]: "@//a:A",
            ["A 2"]: "@//b:A (App)",
            ["A 3"]: "@//b:A (Library)",
            ["B"]: "B",
            ["C 1"]: "@//c:A (Library)",
            ["C 2"]: "@//c:a (App)",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Product Type

    func test_productType() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A 1",
                label: "//:A",
                xcodeConfigurations: ["Debug"], // No effect
                productType: .staticLibrary
            ),
            .mock(
                id: "A 2",
                label: "//:A",
                xcodeConfigurations: ["Release"], // No effect,
                productType: .application
            ),
            .mock(
                id: "B",
                label: "//:B",
                productType: .staticLibrary
            ),
            // The following targets only differ by case
            .mock(
                id: "C 1",
                label: "//:C",
                productType: .staticLibrary
            ),
            .mock(
                id: "C 2",
                label: "//:c",
                productType: .application
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A 1"]: "A (Library)",
            ["A 2"]: "A (App)",
            ["B"]: "B",
            ["C 1"]: "C (Library)",
            ["C 2"]: "c (App)",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_productType_sameName() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A 1",
                label: "//:A",
                productType: .application,
                platform: .iOSDevice
            ),
            .mock(
                id: "A 2",
                label: "//:A",
                productType: .watch2App,
                platform: .watchOSSimulator
            ),
            .mock(
                id: "B",
                label: "//:B",
                productType: .staticLibrary,
                platform: .macOS
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A 1"]: "A (iOS)",
            ["A 2"]: "A (watchOS)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Architecture

    func test_architecture() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-AppleSilicon",
                label: "//:A",
                xcodeConfigurations: ["Debug"], // No effect
                arch: "arm64"
            ),
            .mock(
                id: "A-Intel",
                label: "//:A",
                xcodeConfigurations: ["Release"], // No effect
                arch: "x86_64"
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-AppleSilicon"]: "A (arm64)",
            ["A-Intel"]: "A (x86_64)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Minimum OS Version

    func test_minimumOS() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-15.1",
                label: "//:A",
                xcodeConfigurations: ["Debug"], // No effect
                osVersion: "15.1",
                arch: "arm64" // No effect
            ),
            .mock(
                id: "A-13.2",
                label: "//:A",
                xcodeConfigurations: ["Release"], // No effect
                osVersion: "13.2",
                arch: "x86_64" // No effect
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-15.1"]: "A (iOS 15.1)",
            ["A-13.2"]: "A (iOS 13.2)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Environment

    func test_environment() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Device",
                label: "//:A",
                xcodeConfigurations: ["Debug"], // No effect
                platform: .iOSDevice,
                arch: "arm64" // No effect
            ),
            .mock(
                id: "A-Simulator",
                label: "//:A",
                xcodeConfigurations: ["Release"], // No effect
                platform: .iOSSimulator,
                arch: "x86_64" // No effect
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-Device"]: "A (Device)",
            ["A-Simulator"]: "A (Simulator)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_environment_multipleXcodeConfigurations() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Device-R",
                label: "//:A",
                xcodeConfigurations: ["Release"],
                platform: .iOSDevice,
                arch: "arm64" // No effect
            ),
            .mock(
                id: "A-Device-D",
                label: "//:A",
                xcodeConfigurations: ["Debug"],
                platform: .iOSDevice,
                arch: "arm64" // No effect
            ),
            .mock(
                id: "A-Simulator-R",
                label: "//:A",
                xcodeConfigurations: ["Release"],
                platform: .iOSSimulator,
                arch: "x86_64" // No effect
            ),
            .mock(
                id: "A-Simulator-D",
                label: "//:A",
                xcodeConfigurations: ["Debug"],
                platform: .iOSSimulator,
                arch: "x86_64" // No effect
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
            keys: [
                ["A-Device-R", "A-Device-D"],
                ["A-Simulator-R", "A-Simulator-D"],
                ["B"],
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-Device-R", "A-Device-D"]: "A (Device)",
            ["A-Simulator-R", "A-Simulator-D"]: "A (Simulator)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Operating System

    func test_operatingSystem() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-iOS",
                label: "//:A",
                xcodeConfigurations: ["Debug"], // No effect
                platform: .iOSDevice,
                osVersion: "15.1", // No effect
                arch: "arm64" // No effect
            ),
            .mock(
                id: "A-macOS",
                label: "//:A",
                xcodeConfigurations: ["Release"], // No effect
                platform: .macOS,
                osVersion: "12.0", // No effect
                arch: "x86_64" // No effect
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-iOS"]: "A (iOS)",
            ["A-macOS"]: "A (macOS)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_productTypeAndOperatingSystem() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-iOS-Library",
                label: "//:A",
                productType: .staticLibrary,
                platform: .iOSSimulator
            ),
            .mock(
                id: "A-macOS-Library",
                label: "//:A",
                productType: .staticLibrary,
                platform: .macOS
            ),
            .mock(
                id: "A-macOS-App",
                label: "//:A",
                productType: .application,
                platform: .macOS
            ),
            .mock(
                id: "B",
                label: "//:B",
                productType: .staticLibrary,
                platform: .macOS
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-iOS-Library"]: "A (Library) (iOS)",
            ["A-macOS-Library"]: "A (Library) (macOS)",
            ["A-macOS-App"]: "A (App)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Xcode Configuration

    func test_xcodeConfiguration() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Debug",
                label: "//:A",
                xcodeConfigurations: ["Debug"]
            ),
            .mock(
                id: "A-Release-and-Profile",
                label: "//:A",
                xcodeConfigurations: ["Release", "Profile"]
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-Debug"]: "A (Debug)",
            ["A-Release-and-Profile"]: "A (Profile, Release)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Configuration

    func test_configuration() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A 1",
                label: "//:A"
            ),
            .mock(
                id: "A 2",
                label: "//:A"
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A 1"]: "A (\(ProductTypeComponents.prettyConfigurations(["1"])))",
            ["A 2"]: "A (\(ProductTypeComponents.prettyConfigurations(["2"])))",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_productTypeAndConfiguration() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Library 1",
                label: "//:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "A-Library 2",
                label: "//:A",
                productType: .staticLibrary
            ),
            .mock(
                id: "A-App 2",
                label: "//:A",
                productType: .application
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-Library 1"]: """
A (Library) (\(ProductTypeComponents.prettyConfigurations(["1"])))
""",
            ["A-Library 2"]: """
A (Library) (\(ProductTypeComponents.prettyConfigurations(["2"])))
""",
            ["A-App 2"]: "A (App)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_operatingSystemAndConfiguration() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-iOS 1",
                label: "//:A",
                platform: .iOSDevice
            ),
            .mock(
                id: "A-iOS 2",
                label: "//:A",
                platform: .iOSDevice
            ),
            .mock(
                id: "A-macOS 2",
                label: "//:A",
                platform: .macOS
            ),
            .mock(
                id: "B",
                label: "//:B"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(targets: targets)

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-iOS 1"]: """
A (iOS) (\(ProductTypeComponents.prettyConfigurations(["1"])))
""",
            ["A-iOS 2"]: """
A (iOS) (\(ProductTypeComponents.prettyConfigurations(["2"])))
""",
            ["A-macOS 2"]: "A (macOS)",
            ["B"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    // MARK: - Consolidated Targets

    func test_consolidated() throws {
        // Arrange
        let targets: [Target] = [
            .mock(
                id: "iOS-Simulator",
                label: "//:T",
                platform: .iOSSimulator,
                osVersion: "11.0" // No effect
            ),
            .mock(
                id: "iOS-Device",
                label: "//:T",
                platform: .iOSDevice,
                osVersion: "11.3" // No effect
            ),
            .mock(
                id: "watchOS-Simulator",
                label: "//:T",
                platform: .watchOSSimulator,
                osVersion: "7.0" // No effect
            ),
            .mock(
                id: "watchOS-Device",
                label: "//:T",
                platform: .watchOSDevice,
                osVersion: "7.2" // No effect
            ),
            .mock(
                id: "tvOS-Simulator",
                label: "//:T",
                platform: .tvOSSimulator,
                osVersion: "9.0" // No effect
            ),
            .mock(
                id: "tvOS-Device",
                label: "//:T",
                platform: .tvOSDevice,
                osVersion: "9.1" // No effect
            ),
            .mock(
                id: "macOS",
                label: "//:T",
                platform: .macOS,
                osVersion: "12.0" // No effect
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
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
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            [
                "iOS-Simulator",
                "iOS-Device",
                "watchOS-Simulator",
                "watchOS-Device",
                "tvOS-Simulator",
                "tvOS-Device",
                "macOS",
            ]: "T",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_consolidated_operatingSystem() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-iOS-Simulator",
                label: "//:A",
                platform: .iOSSimulator,
                osVersion: "15.0" // No effect
            ),
            .mock(
                id: "A-iOS-Device",
                label: "//:A",
                platform: .iOSDevice,
                osVersion: "15.0" // No effect
            ),
            .mock(
                id: "A-tvOS-Device",
                label: "//:A",
                platform: .tvOSDevice,
                osVersion: "12.0" // No effect
            ),
            .mock(
                id: "A-watchOS-Device",
                label: "//:A",
                platform: .watchOSDevice,
                osVersion: "9.0" // No effect
            ),
            .mock(
                id: "B-iOS-Simulator",
                label: "//:B",
                platform: .iOSSimulator,
                osVersion: "15.0" // No effect
            ),
            .mock(
                id: "B-iOS-Device",
                label: "//:B",
                platform: .iOSDevice,
                osVersion: "14.0" // No effect
            ),
            .mock(
                id: "B-tvOS-Device",
                label: "//:B",
                platform: .tvOSDevice,
                osVersion: "12.0" // No effect
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
            keys: [
                ["A-iOS-Simulator", "A-iOS-Device", "A-tvOS-Device"],
                ["A-watchOS-Device"],
                ["B-iOS-Simulator", "B-iOS-Device", "B-tvOS-Device"],
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["A-iOS-Simulator", "A-iOS-Device", "A-tvOS-Device"]:
                "A (iOS, tvOS)",
            ["A-watchOS-Device"]: "A (watchOS)",
            ["B-iOS-Simulator", "B-iOS-Device", "B-tvOS-Device"]: "B",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_consolidated_minimumOS() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-iOS-Device-11.0",
                label: "//:A",
                platform: .iOSDevice,
                osVersion: "11.0"
            ),
            .mock(
                id: "A-iOS-Device-13.0",
                label: "//:A",
                platform: .iOSDevice,
                osVersion: "13.0"
            ),
            .mock(
                id: "A-tvOS-Device-12.0",
                label: "//:A",
                platform: .tvOSDevice,
                osVersion: "12.0"
            ),
            .mock(
                id: "A-tvOS-Simulator-11.0",
                label: "//:A",
                platform: .tvOSSimulator,
                osVersion: "11.0"
            ),
            .mock(
                id: "B-iOS-Device-11.0",
                label: "//:B",
                platform: .iOSDevice,
                osVersion: "11.0"
            ),
            .mock(
                id: "B-iOS-Simulator-11.0",
                label: "//:B",
                platform: .iOSSimulator,
                osVersion: "11.0"
            ),
            .mock(
                id: "B-iOS-Device-12.0",
                label: "//:B",
                platform: .iOSDevice,
                osVersion: "12.0"
            ),
            .mock(
                id: "B-iOS-Simulator-12.0",
                label: "//:B",
                platform: .iOSSimulator,
                osVersion: "12.0"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
            keys: [
                [
                    "A-iOS-Device-11.0",
                    "A-tvOS-Device-12.0",
                    "A-tvOS-Simulator-11.0",
                ],
                ["A-iOS-Device-13.0"],
                ["B-iOS-Device-11.0", "B-iOS-Simulator-11.0"],
                ["B-iOS-Device-12.0", "B-iOS-Simulator-12.0"],
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            [
                "A-iOS-Device-11.0",
                "A-tvOS-Device-12.0",
                "A-tvOS-Simulator-11.0",
            ]: "A (iOS 11.0, tvOS)",
            ["A-iOS-Device-13.0"]: "A (iOS 13.0)",
            ["B-iOS-Device-11.0", "B-iOS-Simulator-11.0"]: "B (iOS 11.0)",
            ["B-iOS-Device-12.0", "B-iOS-Simulator-12.0"]: "B (iOS 12.0)",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_consolidated_minimumOSAndEnvironment() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-iOS-Device-11.0",
                label: "//:A",
                platform: .iOSDevice,
                osVersion: "11.0"
            ),
            .mock(
                id: "A-iOS-Simulator-13.0",
                label: "//:A",
                platform: .iOSSimulator,
                osVersion: "13.0"
            ),
            .mock(
                id: "A-tvOS-Device-12.0",
                label: "//:A",
                platform: .tvOSDevice,
                osVersion: "12.0"
            ),
            .mock(
                id: "B-iOS-Device-11.0",
                label: "//:B",
                platform: .iOSDevice,
                osVersion: "11.0"
            ),
            .mock(
                id: "B-iOS-Simulator-13.0",
                label: "//:B",
                platform: .iOSSimulator,
                osVersion: "13.0"
            ),
            .mock(
                id: "B-tvOS-Device-12.0",
                label: "//:B",
                platform: .tvOSDevice,
                osVersion: "12.0"
            ),
            .mock(
                id: "B-iOS-Simulator-14.0",
                label: "//:B",
                platform: .iOSSimulator,
                osVersion: "14.0"
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
            keys: [
                [
                    "A-iOS-Device-11.0",
                    "A-iOS-Simulator-13.0",
                    "A-tvOS-Device-12.0",
                ],
                [
                    "B-iOS-Device-11.0",
                    "B-iOS-Simulator-13.0",
                    "B-tvOS-Device-12.0",
                ],
                ["B-iOS-Simulator-14.0"],
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            [
                "A-iOS-Device-11.0",
                "A-iOS-Simulator-13.0",
                "A-tvOS-Device-12.0",
            ]: "A",
            [
                "B-iOS-Device-11.0",
                "B-iOS-Simulator-13.0",
                "B-tvOS-Device-12.0",
            ]: """
B (iOS 11.0 Device, iOS 13.0 Simulator, tvOS)
""",
            ["B-iOS-Simulator-14.0"]: "B (iOS 14.0)",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_consolidated_environment() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "iOS-Device",
                label: "//:A",
                platform: .iOSDevice
            ),
            .mock(
                id: "iOS-Simulator",
                label: "//:A",
                platform: .iOSSimulator
            ),
            .mock(
                id: "tvOS-Device",
                label: "//:A",
                platform: .tvOSDevice
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
            keys: [
                ["iOS-Device", "tvOS-Device"],
                ["iOS-Simulator"],
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["iOS-Device", "tvOS-Device"]: "A (iOS Device, tvOS)",
            ["iOS-Simulator"]: "A (iOS Simulator)",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }

    func test_consolidated_operatingSystemAndConfiguration() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "iOS-Device 1",
                label: "//:A",
                platform: .iOSDevice
            ),
            .mock(
                id: "iOS-Device 2",
                label: "//:A",
                platform: .iOSDevice
            ),
            .mock(
                id: "tvOS-Device 3",
                label: "//:A",
                platform: .tvOSDevice
            ),
        ]
        let consolidatedTargets = Array<ConsolidatedTarget>(
            keys: [
                ["iOS-Device 1", "tvOS-Device 3"],
                ["iOS-Device 2"],
            ],
            allTargets: targets
        )

        let expectedTargetNames: [ConsolidatedTarget.Key: String] = [
            ["iOS-Device 1", "tvOS-Device 3"]: """
A (iOS, tvOS) (\(ProductTypeComponents.prettyConfigurations(["1", "3"])))
""",
            ["iOS-Device 2"]: """
A (iOS) (\(ProductTypeComponents.prettyConfigurations(["2"])))
""",
        ]

        // Act

        let disambiguatedTargets =
            Generator.DisambiguateTargets.defaultCallable(consolidatedTargets)

        // Assert

        XCTAssertNoDifference(
            disambiguatedTargets,
            names: expectedTargetNames,
            targets: consolidatedTargets
        )
    }
}

func XCTAssertNoDifference(
    _ disambiguatedTargets: [DisambiguatedTarget],
    names: [ConsolidatedTarget.Key: String],
    targets: [ConsolidatedTarget],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNoDifference(
        disambiguatedTargets
            .map { KeyAndValue(key: $0.target.key, value: $0.name) }
            .sorted(),
        names.map(KeyAndValue.init).sorted(),
        file: file,
        line: line
    )
    XCTAssertNoDifference(
        disambiguatedTargets
            .map { KeyAndValue(key: $0.target.key, value: $0.target) }
            .sorted(),
        targets
            .map { KeyAndValue(key: $0.key, value: $0) }
            .sorted(),
        file: file,
        line: line
    )
}

struct KeyAndValue<Key, Value> {
    let key: Key
    let value: Value

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

extension KeyAndValue: Equatable where Key: Equatable, Value: Equatable {}
extension KeyAndValue: Hashable where Key: Hashable, Value: Hashable {}
extension KeyAndValue: Comparable where Key: Comparable, Value: Equatable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.key < rhs.key
    }
}

extension Array where Element == ConsolidatedTarget {
    init(targets: [Target]) {
        self = targets.map { target in
            ConsolidatedTarget(
                key: [target.id],
                sortedTargets: [target]
            )
        }
    }

    init(keys: Set<Set<TargetID>>, allTargets: [Target]) {
        self = keys.map { targetIDs in
            ConsolidatedTarget(
                ConsolidatedTarget.Key(targetIDs.sorted()),
                allTargets: allTargets
            )
        }
    }
}

extension ConsolidatedTarget.Key: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.sortedIds.first! < rhs.sortedIds.first!
    }
}
