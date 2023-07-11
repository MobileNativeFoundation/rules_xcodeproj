import CustomDump
import GeneratorCommon
import PBXProj
import XCTest

@testable import pbxproject_targets

final class ConsolidateTargetsTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "1",
                platform: .iOSSimulator
            ),
            .mock(
                id: "2",
                platform: .iOSDevice
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init(["1", "2"], allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_not_different_enough() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "1",
                platform: .iOSSimulator
            ),
            .mock(
                id: "2",
                platform: .iOSSimulator
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init(["1"], allTargets: targets),
            .init(["2"], allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_xcodeConfiguration() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Simulator-Debug",
                xcodeConfigurations: ["Debug"],
                platform: .iOSSimulator
            ),
            .mock(
                id: "A-Simulator-Release",
                xcodeConfigurations: ["Release"],
                platform: .iOSSimulator
            ),
            .mock(
                id: "A-Simulator-Profile",
                xcodeConfigurations: ["Profile"],
                platform: .iOSSimulator
            ),
            .mock(
                id: "A-Device-Debug",
                xcodeConfigurations: ["Debug"],
                platform: .iOSDevice
            ),
            .mock(
                id: "A-Device-ReleaseProfile",
                xcodeConfigurations: ["Release", "Profile"],
                platform: .iOSDevice
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init([
                "A-Simulator-Debug",
                "A-Simulator-Release",
                "A-Simulator-Profile",
                "A-Device-Debug",
                "A-Device-ReleaseProfile",
            ],
            allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_xcodeConfiguration_differentDeps() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Simulator-Debug",
                label: "//:A",
                xcodeConfigurations: ["Debug"],
                platform: .iOSSimulator,
                dependencies: ["B-Simulator-Debug"]
            ),
            .mock(
                id: "A-Simulator-Release",
                label: "//:A",
                xcodeConfigurations: ["Release"],
                platform: .iOSSimulator,
                dependencies: ["B-Simulator-Release"]
            ),
            .mock(
                id: "A-Device-Debug",
                label: "//:A",
                xcodeConfigurations: ["Debug"],
                platform: .iOSDevice,
                dependencies: ["C-Device-Debug"]
            ),
            .mock(
                id: "A-Device-Release",
                label: "//:A",
                xcodeConfigurations: ["Release"],
                platform: .iOSDevice,
                dependencies: ["C-Device-Release"]
            ),
            .mock(
                id: "B-Simulator-Debug",
                label: "//:B",
                xcodeConfigurations: ["Debug"],
                platform: .iOSSimulator
            ),
            .mock(
                id: "B-Simulator-Release",
                label: "//:B",
                xcodeConfigurations: ["Release"],
                platform: .iOSSimulator
            ),
            .mock(
                id: "C-Device-Debug",
                label: "//:C",
                xcodeConfigurations: ["Debug"],
                platform: .iOSDevice
            ),
            .mock(
                id: "C-Device-Release",
                label: "//:C",
                xcodeConfigurations: ["Release"],
                platform: .iOSDevice
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init(
                ["A-Simulator-Debug", "A-Simulator-Release"],
                allTargets: targets
            ),
            .init(
                ["A-Device-Debug", "A-Device-Release"],
                allTargets: targets
            ),
            .init(
                ["B-Simulator-Debug", "B-Simulator-Release"],
                allTargets: targets
            ),
            .init(
                ["C-Device-Debug", "C-Device-Release"],
                allTargets: targets
            ),
        ]
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
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_multiple_archs() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Simulator-AppleSilicon",
                label: "//:A",
                platform: .iOSSimulator,
                arch: "arm64"
            ),
            .mock(
                id: "A-Simulator-Intel",
                label: "//:A",
                platform: .iOSSimulator,
                arch: "x86_64"
            ),
            .mock(
                id: "A-Device",
                label: "//:A",
                platform: .iOSDevice,
                arch: "arm64"
            ),
            .mock(
                id: "B-Simulator-Intel",
                label: "//:B",
                platform: .iOSSimulator,
                arch: "x86_64"
            ),
            .mock(
                id: "B-Device",
                label: "//:B",
                platform: .iOSDevice,
                arch: "arm64"
            ),
            .mock(
                id: "C-Intel",
                label: "//:C",
                platform: .macOS,
                arch: "x86_64"
            ),
            .mock(
                id: "C-AppleSilicon",
                label: "//:C",
                platform: .macOS,
                arch: "arm64"
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            // Mergable
            .init(
                ["A-Simulator-AppleSilicon", "A-Device"],
                allTargets: targets
            ),
            .init(
                ["B-Simulator-Intel", "B-Device"]
                , allTargets: targets
            ),
            // Can't merge same arch
            .init(
                ["A-Simulator-Intel"],
                allTargets: targets
            ),
            .init(
                ["C-Intel"],
                allTargets: targets
            ),
            .init(
                ["C-AppleSilicon"],
                allTargets: targets
            ),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_label() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Simulator",
                label: "//:A",
                platform: .iOSSimulator,
                arch: "arm64"
            ),
            .mock(
                id: "B-Simulator",
                label: "//:B",
                platform: .iOSSimulator,
                arch: "x86_64"
            ),
            .mock(
                id: "B-Device",
                label: "//:B",
                platform: .iOSDevice,
                arch: "arm64"
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init(["A-Simulator"], allTargets: targets),
            .init(["B-Simulator", "B-Device"], allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_type() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "1",
                productType: .staticLibrary,
                platform: .iOSSimulator
            ),
            .mock(
                id: "2",
                productType: .framework,
                platform: .iOSDevice
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init(["1"], allTargets: targets),
            .init(["2"], allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_minimumOS() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "Simulator-11.0",
                platform: .iOSSimulator,
                osVersion: "11.0"
            ),
            .mock(
                id: "Device-12.0",
                platform: .iOSDevice,
                osVersion: "12.0"
            ),
            .mock(
                id: "Simulator-13.0",
                platform: .iOSSimulator,
                osVersion: "13.0"
            ),
            .mock(
                id: "Device-13.0",
                platform: .iOSDevice,
                osVersion: "13.0"
            ),
            .mock(
                id: "Simulator-13.2",
                platform: .iOSSimulator,
                osVersion: "13.2"
            ),
            .mock(
                id: "Device-13.2",
                platform: .iOSDevice,
                osVersion: "13.2"
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init(["Simulator-11.0", "Device-12.0"], allTargets: targets),
            .init(["Simulator-13.0", "Device-13.0"], allTargets: targets),
            .init(["Simulator-13.2", "Device-13.2"], allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_os() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "iOS-Simulator",
                platform: .iOSSimulator,
                osVersion: "11.0"
            ),
            .mock(
                id: "iOS-Device",
                platform: .iOSDevice,
                osVersion: "11.0"
            ),
            .mock(
                id: "watchOS-Simulator",
                platform: .watchOSSimulator,
                osVersion: "7.0"
            ),
            .mock(
                id: "watchOS-Device",
                platform: .watchOSDevice,
                osVersion: "7.0"
            ),
            .mock(
                id: "tvOS-Simulator",
                platform: .tvOSSimulator,
                osVersion: "9.0"
            ),
            .mock(
                id: "tvOS-Device",
                platform: .tvOSDevice,
                osVersion: "9.0"
            ),
            .mock(
                id: "macOS",
                platform: .macOS,
                osVersion: "12.0"
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            .init([
                "iOS-Simulator",
                "iOS-Device",
                "tvOS-Simulator",
                "tvOS-Device",
                "macOS",
            ], allTargets: targets),
            .init([
                "watchOS-Simulator",
                "watchOS-Device",
            ], allTargets: targets),
        ]
        let expectedMessagesLogged: Set<StubLogger.MessageLogged> = []

        // Act

        let logger = StubLogger()
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }

    func test_different_dependencies() throws {
        // Arrange

        let targets: [Target] = [
            .mock(
                id: "A-Simulator",
                label: "//:A",
                platform: .iOSSimulator,
                dependencies: ["B-Simulator", "W-Simulator"]
            ),
            .mock(
                id: "A-Device",
                label: "//:A",
                platform: .iOSDevice,
                dependencies: ["B-Device", "W-Device"]
            ),
            .mock(
                id: "B-Simulator",
                label: "//:B",
                platform: .iOSSimulator,
                dependencies: ["C-Simulator", "X-Simulator"]
            ),
            .mock(
                id: "B-Device",
                label: "//:B",
                platform: .iOSDevice,
                dependencies: ["C-Device", "X-Device"]
            ),
            .mock(
                id: "C-Simulator",
                label: "//:C",
                platform: .iOSSimulator,
                dependencies: ["Y-Simulator"]
            ),
            .mock(
                id: "C-Device",
                label: "//:C",
                platform: .iOSDevice,
                dependencies: ["Z-Device"]
            ),
            // Leafs
            .mock(
                id: "W-Simulator",
                label: "//:W",
                platform: .iOSSimulator
            ),
            .mock(
                id: "W-Device",
                label: "//:W",
                platform: .iOSDevice
            ),
            .mock(
                id: "X-Simulator",
                label: "//:X",
                platform: .iOSSimulator
            ),
            .mock(
                id: "X-Device",
                label: "//:X",
                platform: .iOSDevice
            ),
            .mock(
                id: "Y-Simulator",
                label: "//:Y",
                platform: .iOSSimulator
            ),
            .mock(
                id: "Y-Device",
                label: "//:Y",
                platform: .iOSDevice
            ),
            .mock(
                id: "Z-Simulator",
                label: "//:Z",
                platform: .iOSSimulator
            ),
            .mock(
                id: "Z-Device",
                label: "//:Z",
                platform: .iOSDevice
            ),
        ]
        let expectedConsolidatedTargets: [ConsolidatedTarget] = [
            // Normal merge
            .init(["W-Simulator", "W-Device"], allTargets: targets),
            .init(["X-Simulator", "X-Device"], allTargets: targets),
            .init(["Y-Simulator", "Y-Device"], allTargets: targets),
            .init(["Z-Simulator", "Z-Device"], allTargets: targets),
            // Has a divergent dependencies
            .init(["C-Simulator"], allTargets: targets),
            .init(["C-Device"], allTargets: targets),
            // Transitively has divergent dependencies
            .init(["B-Simulator"], allTargets: targets),
            .init(["B-Device"], allTargets: targets),
            .init(["A-Simulator"], allTargets: targets),
            .init(["A-Device"], allTargets: targets),
        ]
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
        let consolidatedTargets = try Generator.ConsolidateTargets
            .defaultCallable(targets, logger: logger)

        // Assert

        XCTAssertNoDifference(
            consolidatedTargets: consolidatedTargets,
            expectedConsolidatedTargets: expectedConsolidatedTargets
        )
        XCTAssertNoDifference(
            Set(logger.messagesLogged),
            expectedMessagesLogged
        )
    }
}

func XCTAssertNoDifference(
    consolidatedTargets: [ConsolidatedTarget],
    expectedConsolidatedTargets: [ConsolidatedTarget],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNoDifference(
        consolidatedTargets.sorted { lhs, rhs in
            lhs.sortedTargets.first!.id < rhs.sortedTargets.first!.id
        },
        expectedConsolidatedTargets.sorted { lhs, rhs in
            lhs.sortedTargets.first!.id < rhs.sortedTargets.first!.id
        },
        file: file,
        line: line
    )
}

extension Target {
    static func mock(
        id: TargetID,
        label: BazelLabel = "//some:target",
        xcodeConfigurations: [String] = ["Debug"],
        productType: PBXProductType = .staticLibrary,
        productPath: String = "bazel-out/something.a",
        platform: Platform = .iOSSimulator,
        osVersion: SemanticVersion = "12.0",
        arch: String = "arm64",
        dependencies: [TargetID] = []
    ) -> Self {
        return Self(
            id: id,
            label: label,
            xcodeConfigurations: xcodeConfigurations,
            productType: productType,
            productPath: productPath,
            platform: platform,
            osVersion: osVersion,
            arch: arch,
            dependencies: dependencies
        )
    }
}

final class StubLogger: Logger {
    enum MessageType {
        case debug
        case info
        case warning
        case error
    }

    struct MessageLogged: Equatable, Hashable {
        let type: MessageType
        let message: String

        init(_ type: MessageType, _ message: String) {
            self.type = type
            self.message = message
        }
    }

    var messagesLogged: [MessageLogged] = []

    func logDebug(_ message: String) {
        messagesLogged.append(.init(.debug, message))
    }

    func logInfo(_ message: String) {
        messagesLogged.append(.init(.info, message))
    }

    func logWarning(_ message: String) {
        messagesLogged.append(.init(.warning, message))
    }

    func logError(_ message: String) {
        messagesLogged.append(.init(.error, message))
    }
}

extension ConsolidatedTarget {
    init(_ key: Key, allTargets: [Target]) {
        let ids = key.sortedIds
        let sortedTargets = allTargets
            .filter { ids.contains($0.id) }
            .sorted { $0.id < $1.id }

        self.init(key: key, sortedTargets: sortedTargets)
    }
}

extension ConsolidatedTarget.Key: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: TargetID...) {
        self.init(elements.sorted())
    }
}
