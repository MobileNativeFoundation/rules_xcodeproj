import CustomDump
import XCTest

@testable import generator

final class ConsolidateTargetsTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "T", path: "A/T")
            ),
            "B": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "T", path: "B/T")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A", "B"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_differentXcodeConfiguration() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A-Simulator-Debug": .mock(
                xcodeConfigurations: ["Debug"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "A/T")
            ),
            "A-Simulator-Release": .mock(
                xcodeConfigurations: ["Release"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "A/T")
            ),
            "A-Simulator-Profile": .mock(
                xcodeConfigurations: ["Profile"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "A/T")
            ),
            "A-Device-Debug": .mock(
                xcodeConfigurations: ["Debug"],
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "A/T")
            ),
            "A-Device-ReleaseProfile": .mock(
                xcodeConfigurations: ["Release", "Profile"],
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "A/T")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                [
                    "A-Simulator-Debug",
                    "A-Simulator-Release",
                    "A-Simulator-Profile",
                    "A-Device-Debug",
                    "A-Device-ReleaseProfile",
                ],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_differentXcodeConfiguration_differentDeps() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A-Simulator-Debug": .mock(
                xcodeConfigurations: ["Debug"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "A1/T"),
                dependencies: ["B-Simulator-Debug"]
            ),
            "A-Simulator-Release": .mock(
                xcodeConfigurations: ["Release"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "A2/T"),
                dependencies: ["B-Simulator-Release"]
            ),
            "A-Device-Debug": .mock(
                xcodeConfigurations: ["Debug"],
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "A3/T"),
                dependencies: ["C-Device-Debug"]
            ),
            "A-Device-Release": .mock(
                xcodeConfigurations: ["Release"],
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "A4/T"),
                dependencies: ["C-Device-Release"]
            ),
            "B-Simulator-Debug": .mock(
                xcodeConfigurations: ["Debug"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "B", path: "B1/T")
            ),
            "B-Simulator-Release": .mock(
                xcodeConfigurations: ["Release"],
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "B", path: "B2/T")
            ),
            "C-Device-Debug": .mock(
                xcodeConfigurations: ["Debug"],
                platform: .device(),
                product: .init(type: .staticLibrary, name: "C", path: "C1/T")
            ),
            "C-Device-Release": .mock(
                xcodeConfigurations: ["Release"],
                platform: .device(),
                product: .init(type: .staticLibrary, name: "C", path: "C2/T")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A-Simulator-Debug", "A-Simulator-Release"],
                ["A-Device-Debug", "A-Device-Release"],
                ["B-Simulator-Debug", "B-Simulator-Release"],
                ["C-Device-Debug", "C-Device-Release"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = [
            .init(.warning, """
Was unable to consolidate target groupings \
"[A-Device-Debug, A-Device-Release], [A-Simulator-Debug, A-Simulator-Release]" \
since they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
        ]

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_not_different_enough() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A": .mock(
                configuration: "A",
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "T", path: "A/T")
            ),
            "B": .mock(
                configuration: "B",
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "T", path: "B/T")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A"],
                ["B"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_multiple_archs() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A-Simulator-AppleSilicon": .mock(
                platform: .simulator(arch: "arm64"),
                product: .init(type: .staticLibrary, name: "A", path: "SA/A")
            ),
            "A-Simulator-Intel": .mock(
                platform: .simulator(arch: "x86_64"),
                product: .init(type: .staticLibrary, name: "A", path: "SI/A")
            ),
            "A-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "D/A")
            ),
            "B-Simulator-Intel": .mock(
                platform: .simulator(arch: "x86_64"),
                product: .init(type: .staticLibrary, name: "B", path: "SI/B")
            ),
            "B-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "B", path: "D/B")
            ),
            "C-Intel": .mock(
                platform: .macOS(arch: "x86_64"),
                product: .init(type: .staticLibrary, name: "C", path: "I/C")
            ),
            "C-AppleSilicon": .mock(
                platform: .macOS(arch: "arm64"),
                product: .init(type: .staticLibrary, name: "C", path: "D/C")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                // Mergable
                ["A-Simulator-AppleSilicon", "A-Device"],
                ["B-Simulator-Intel", "B-Device"],
                // Can't merge same arch
                ["A-Simulator-Intel"],
                ["C-Intel"],
                ["C-AppleSilicon"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_label() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A": .mock(
                platform: .simulator(arch: "arm64"),
                product: .init(type: .staticLibrary, name: "T1", path: "A/T1")
            ),
            "B": .mock(
                platform: .simulator(arch: "x86_64"),
                product: .init(type: .staticLibrary, name: "T2", path: "B/T2")
            ),
            "C": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "T2", path: "C/T2")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A"],
                ["B", "C"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_type() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "T", path: "A/T.a")
            ),
            "B": .mock(
                platform: .device(),
                product: .init(type: .framework, name: "T", path: "B/T.fram")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A"],
                ["B"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_minimumOS() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A1": .mock(
                platform: .simulator(minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "A", path: "1/A")
            ),
            "A2": .mock(
                platform: .device(minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "A", path: "2/A")
            ),
            "B1": .mock(
                platform: .simulator(minimumOsVersion: "13.0"),
                product: .init(type: .staticLibrary, name: "B", path: "S13/B")
            ),
            "B2": .mock(
                platform: .device(minimumOsVersion: "13.0"),
                product: .init(type: .staticLibrary, name: "B", path: "D13/B")
            ),
            "B3": .mock(
                platform: .simulator(minimumOsVersion: "13.2"),
                product: .init(type: .staticLibrary, name: "B", path: "S13.2/B")
            ),
            "B4": .mock(
                platform: .device(minimumOsVersion: "13.2"),
                product: .init(type: .staticLibrary, name: "B", path: "D13.2/B")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                ["A1", "A2"],
                ["B1", "B2"],
                ["B3", "B4"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_os() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "iOS-Simulator": .mock(
                platform: .simulator(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "T", path: "IS/T")
            ),
            "iOS-Device": .mock(
                platform: .device(os: .iOS, minimumOsVersion: "11.0"),
                product: .init(type: .staticLibrary, name: "T", path: "ID/T")
            ),
            "watchOS-Simulator": .mock(
                platform: .simulator(os: .watchOS, minimumOsVersion: "7.0"),
                product: .init(type: .staticLibrary, name: "T", path: "WS/T")
            ),
            "watchOS-Device": .mock(
                platform: .device(os: .watchOS, minimumOsVersion: "7.0"),
                product: .init(type: .staticLibrary, name: "T", path: "WD/T")
            ),
            "tvOS-Simulator": .mock(
                platform: .simulator(os: .tvOS, minimumOsVersion: "9.0"),
                product: .init(type: .staticLibrary, name: "T", path: "TS/T")
            ),
            "tvOS-Device": .mock(
                platform: .device(os: .tvOS, minimumOsVersion: "9.0"),
                product: .init(type: .staticLibrary, name: "T", path: "TD/T")
            ),
            "macOS": .mock(
                platform: .macOS(minimumOsVersion: "12.0"),
                product: .init(type: .staticLibrary, name: "T", path: "M/T")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                [
                    "iOS-Simulator",
                    "iOS-Device",
                    "tvOS-Simulator",
                    "tvOS-Device",
                    "macOS",
                ],
                [
                    "watchOS-Simulator",
                    "watchOS-Device",
                ],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_dependencies() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "A", path: "S/A"),
                dependencies: ["B-Simulator", "W-Simulator"]
            ),
            "A-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "A", path: "D/A"),
                dependencies: ["B-Device", "W-Device"]
            ),
            "B-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "B", path: "S/B"),
                dependencies: ["C-Simulator", "X-Simulator"]
            ),
            "B-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "B", path: "D/B"),
                dependencies: ["C-Device", "X-Device"]
            ),
            "C-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "C", path: "S/C"),
                dependencies: ["Y-Simulator"]
            ),
            "C-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "C", path: "D/C"),
                dependencies: ["Z-Device"]
            ),
            // Leafs
            "W-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "W", path: "S/W")
            ),
            "W-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "W", path: "D/W")
            ),
            "X-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "X", path: "S/X")
            ),
            "X-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "X", path: "D/X")
            ),
            "Y-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "Y", path: "S/Y")
            ),
            "Y-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "Y", path: "D/Y")
            ),
            "Z-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "Z", path: "S/Z")
            ),
            "Z-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "Z", path: "D/Z")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                // Normal merge
                ["W-Simulator", "W-Device"],
                ["X-Simulator", "X-Device"],
                ["Y-Simulator", "Y-Device"],
                ["Z-Simulator", "Z-Device"],
                // Has a divergent dependencies
                ["C-Simulator"],
                ["C-Device"],
                // Transitively has divergent dependencies
                ["B-Simulator"],
                ["B-Device"],
                ["A-Simulator"],
                ["A-Device"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = [
            .init(.warning, """
Was unable to consolidate target groupings "[C-Device], [C-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
            .init(.warning, """
Was unable to consolidate target groupings "[B-Device], [B-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
            .init(.warning, """
Was unable to consolidate target groupings "[A-Device], [A-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
        ]

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_testHost() throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "A1-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .unitTestBundle, name: "A1", path: "S/A1"),
                testHost: "B1-Simulator"
            ),
            "A1-Device": .mock(
                platform: .device(),
                product: .init(type: .unitTestBundle, name: "A1", path: "D/A1"),
                testHost: "B1-Device"
            ),
            "A2-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .unitTestBundle, name: "A2", path: "S/A2"),
                testHost: "B1-Simulator"
            ),
            "A2-Device": .mock(
                platform: .device(),
                product: .init(type: .unitTestBundle, name: "A2", path: "D/A2"),
                testHost: "B2-Device"
            ),
            "B1-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .application, name: "B1", path: "S/B1"),
                dependencies: ["C-Simulator", "X-Simulator"]
            ),
            "B1-Device": .mock(
                platform: .device(),
                product: .init(type: .application, name: "B1", path: "D/B1"),
                dependencies: ["C-Device", "X-Device"]
            ),
            "B2-Device": .mock(
                platform: .device(),
                product: .init(type: .application, name: "B2", path: "D/B2")
            ),
            "C-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "C", path: "S/C"),
                dependencies: ["Y-Simulator"]
            ),
            "C-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "C", path: "D/C"),
                dependencies: ["Z-Device"]
            ),
            // Leafs
            "X-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "X", path: "S/X")
            ),
            "X-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "X", path: "D/X")
            ),
            "Y-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "Y", path: "S/Y")
            ),
            "Y-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "Y", path: "D/Y")
            ),
            "Z-Simulator": .mock(
                platform: .simulator(),
                product: .init(type: .staticLibrary, name: "Z", path: "S/Z")
            ),
            "Z-Device": .mock(
                platform: .device(),
                product: .init(type: .staticLibrary, name: "Z", path: "D/Z")
            ),
        ]
        let expectedConsolidatedTargets = ConsolidatedTargets(
            allTargets: targets,
            keys: [
                // Normal merge
                ["X-Simulator", "X-Device"],
                ["Y-Simulator", "Y-Device"],
                ["Z-Simulator", "Z-Device"],
                ["B2-Device"],
                // Has a divergent dependencies
                ["C-Simulator"],
                ["C-Device"],
                // Transitively has divergent dependencies
                ["B1-Simulator"],
                ["B1-Device"],
                // Has different testHosts
                ["A2-Simulator"],
                ["A2-Device"],
                // Transitively has divergent testHost dependencies
                ["A1-Simulator"],
                ["A1-Device"],
            ]
        )
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = [
            .init(.warning, """
Was unable to consolidate target groupings "[C-Device], [C-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
            .init(.warning, """
Was unable to consolidate target groupings "[A2-Device], [A2-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
            .init(.warning, """
Was unable to consolidate target groupings "[A1-Device], [A1-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
            .init(.warning, """
Was unable to consolidate target groupings "[B1-Device], [B1-Simulator]" since \
they have conditional dependencies (e.g. `deps`, `test_host`, \
`watch_application`, etc.)
"""),
        ]

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.consolidateTargets(
            targets,
            [:],
            logger: logger
        )

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets.keys,
            expectedConsolidatedTargets.keys
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }
}
