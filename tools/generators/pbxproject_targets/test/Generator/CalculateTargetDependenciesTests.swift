import CustomDump
import XCTest

@testable import pbxproject_targets
@testable import PBXProj

final class CalculateTargetDependenciesTests: XCTestCase {
    func test_dependencies() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    name: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                ),
                dependencies: [
                    "C",
                ]
            ),
            .mock(
                key: ["C"],
                identifier: .init(
                    name: "C",
                    subIdentifier: .init(shard: "00", hash: "12345678"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                ),
                dependencies: []
            ),
        ]
        let identifiers: [TargetID : Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
            "B": identifiedTargets[0].identifier,
            "C": identifiedTargets[1].identifier,
        ]

        let calculateContainerItemProxy = Generator.CalculateContainerItemProxy
            .mock(
                contents: [
                    "{CIP_AB1}",
                    "{CIP_AB2}",
                    "{CIP_C}",
                ]
            )
        let calculateTargetDependency = Generator.CalculateTargetDependency
            .mock(
                contents: [
                    "{TD_AB1}",
                    "{TD_AB2}",
                    "{TD_C}",
                ]
            )

        let cipIdentifier1 = Identifiers.Targets.containerItemProxy(
            from: identifiers["A"]!.subIdentifier,
            to: .bazelDependencies
        )
        let cipIdentifier2 = Identifiers.Targets.containerItemProxy(
            from: identifiers["A"]!.subIdentifier,
            to: identifiers["C"]!.subIdentifier
        )
        let cipIdentifier3 = Identifiers.Targets.containerItemProxy(
            from: identifiers["C"]!.subIdentifier,
            to: .bazelDependencies
        )

        let expectedCalculateContainerItemProxy: [
            Generator.CalculateContainerItemProxy.MockTracker.Called
        ] = [
            .init(identifier: .bazelDependencies),
            .init(identifier: identifiers["C"]!),
            .init(identifier: .bazelDependencies),
        ]
        let expectedCalculateTargetDependency: [
            Generator.CalculateTargetDependency.MockTracker.Called
        ] = [
            .init(
                identifier: .bazelDependencies,
                containerItemProxyIdentifier: cipIdentifier1
            ),
            .init(
                identifier: identifiedTargets[1].identifier,
                containerItemProxyIdentifier: cipIdentifier2
            ),
            .init(
                identifier: .bazelDependencies,
                containerItemProxyIdentifier: cipIdentifier3
            ),
        ]

        let expectedElements: [Element] = [
            .init(
                identifier: cipIdentifier1,
                content: "{CIP_AB1}"
            ),
            .init(
                identifier: Identifiers.Targets.dependency(
                    from: identifiers["A"]!.subIdentifier,
                    to: .bazelDependencies
                ),
                content: "{TD_AB1}"
            ),
            .init(
                identifier: cipIdentifier2,
                content: "{CIP_AB2}"
            ),
            .init(
                identifier: Identifiers.Targets.dependency(
                    from: identifiers["A"]!.subIdentifier,
                    to: identifiers["C"]!.subIdentifier
                ),
                content: "{TD_AB2}"
            ),
            .init(
                identifier: cipIdentifier3,
                content: "{CIP_C}"
            ),
            .init(
                identifier: Identifiers.Targets.dependency(
                    from: identifiers["C"]!.subIdentifier,
                    to: .bazelDependencies
                ),
                content: "{TD_C}"
            ),
        ]

        // Act

        let elements = try Generator.CalculateTargetDependencies
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers,
                calculateContainerItemProxy: calculateContainerItemProxy.mock,
                calculateTargetDependency: calculateTargetDependency.mock
            )

        // Assert

        XCTAssertNoDifference(
            calculateContainerItemProxy.tracker.called,
            expectedCalculateContainerItemProxy
        )
        XCTAssertNoDifference(
            calculateTargetDependency.tracker.called,
            expectedCalculateTargetDependency
        )
        XCTAssertNoDifference(elements, expectedElements)
    }

    func test_noDependencies() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    name: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                ),
                dependencies: []
            ),
            .mock(
                key: ["C"],
                identifier: .init(
                    name: "C",
                    subIdentifier: .init(shard: "00", hash: "12345678"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                ),
                dependencies: []
            ),
        ]
        let identifiers: [TargetID : Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
            "B": identifiedTargets[0].identifier,
            "C": identifiedTargets[1].identifier,
        ]

        let calculateContainerItemProxy = Generator.CalculateContainerItemProxy
            .mock(
                contents: [
                    "{CIP_AB}",
                    "{CIP_C}",
                ]
            )
        let calculateTargetDependency = Generator.CalculateTargetDependency
            .mock(
                contents: [
                    "{TD_AB}",
                    "{TD_C}",
                ]
            )

        let cipIdentifier1 = Identifiers.Targets.containerItemProxy(
            from: identifiers["A"]!.subIdentifier,
            to: .bazelDependencies
        )
        let cipIdentifier2 = Identifiers.Targets.containerItemProxy(
            from: identifiers["C"]!.subIdentifier,
            to: .bazelDependencies
        )

        let expectedCalculateContainerItemProxyCalled: [
            Generator.CalculateContainerItemProxy.MockTracker.Called
        ] = [
            .init(identifier: .bazelDependencies),
            .init(identifier: .bazelDependencies),
        ]
        let expectedCalculateTargetDependencyCalled: [
            Generator.CalculateTargetDependency.MockTracker.Called
        ] = [
            .init(
                identifier: .bazelDependencies,
                containerItemProxyIdentifier: cipIdentifier1
            ),
            .init(
                identifier: .bazelDependencies,
                containerItemProxyIdentifier: cipIdentifier2
            ),
        ]

        let expectedElements: [Element] = [
            .init(
                identifier: cipIdentifier1,
                content: "{CIP_AB}"
            ),
            .init(
                identifier: Identifiers.Targets.dependency(
                    from: identifiers["A"]!.subIdentifier,
                    to: .bazelDependencies
                ),
                content: "{TD_AB}"
            ),
            .init(
                identifier: cipIdentifier2,
                content: "{CIP_C}"
            ),
            .init(
                identifier: Identifiers.Targets.dependency(
                    from: identifiers["C"]!.subIdentifier,
                    to: .bazelDependencies
                ),
                content: "{TD_C}"
            ),
        ]

        // Act

        let elements = try Generator.CalculateTargetDependencies
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers,
                calculateContainerItemProxy: calculateContainerItemProxy.mock,
                calculateTargetDependency: calculateTargetDependency.mock
            )

        // Assert

        XCTAssertNoDifference(
            calculateContainerItemProxy.tracker.called,
            expectedCalculateContainerItemProxyCalled
        )
        XCTAssertNoDifference(
            calculateTargetDependency.tracker.called,
            expectedCalculateTargetDependencyCalled
        )
        XCTAssertNoDifference(elements, expectedElements)
    }
}
