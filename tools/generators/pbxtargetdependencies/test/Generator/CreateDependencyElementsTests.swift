import CustomDump
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class CreateDependencyElementsTests: XCTestCase {
    func test_dependencies() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    pbxProjEscapedName: "AB",
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
                    pbxProjEscapedName: "C",
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

        let createContainerItemProxyElement =
            Generator.CreateContainerItemProxyElement.mock(
                elements: [
                    Element(identifier: "CIP_AB1_ID", content: "{CIP_AB1}"),
                    Element(identifier: "CIP_AB2_ID", content: "{CIP_AB2}"),
                    Element(identifier: "CIP_C_ID", content: "{CIP_C}"),
                ]
            )
        let createTargetDependencyElement =
            Generator.CreateTargetDependencyElement.mock(
                elements: [
                    Element(identifier: "TD_AB1_ID", content: "{TD_AB1}"),
                    Element(identifier: "TD_AB2_ID", content: "{TD_AB2}"),
                    Element(identifier: "TD_C_ID", content: "{TD_C}"),
                ]
            )

        let expectedCreateContainerItemProxyElementCalled: [
            Generator.CreateContainerItemProxyElement.MockTracker.Called
        ] = [
            .init(
                subIdentifier: identifiers["A"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
            .init(
                subIdentifier: identifiers["A"]!.subIdentifier,
                dependencyIdentifier: identifiers["C"]!
            ),
            .init(
                subIdentifier: identifiers["C"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
        ]
        let expectedCreateTargetDependencyElementCalled: [
            Generator.CreateTargetDependencyElement.MockTracker.Called
        ] = [
            .init(
                subIdentifier: identifiers["A"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_AB1_ID"
            ),
            .init(
                subIdentifier: identifiers["A"]!.subIdentifier,
                dependencyIdentifier: identifiedTargets[1].identifier,
                containerItemProxyIdentifier: "CIP_AB2_ID"
            ),
            .init(
                subIdentifier: identifiers["C"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_C_ID"
            ),
        ]

        let expectedElements: [Element] = [
            .init(identifier: "CIP_AB1_ID", content: "{CIP_AB1}"),
            .init(identifier: "TD_AB1_ID", content: "{TD_AB1}"),
            .init(identifier: "CIP_AB2_ID", content: "{CIP_AB2}"),
            .init(identifier: "TD_AB2_ID", content: "{TD_AB2}"),
            .init(identifier: "CIP_C_ID", content: "{CIP_C}"),
            .init(identifier: "TD_C_ID", content: "{TD_C}"),
        ]

        // Act

        let elements = try Generator.CreateDependencyElements
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers,
                createContainerItemProxyElement:
                    createContainerItemProxyElement.mock,
                createTargetDependencyElement:
                    createTargetDependencyElement.mock
            )

        // Assert

        XCTAssertNoDifference(
            createContainerItemProxyElement.tracker.called,
            expectedCreateContainerItemProxyElementCalled
        )
        XCTAssertNoDifference(
            createTargetDependencyElement.tracker.called,
            expectedCreateTargetDependencyElementCalled
        )
        XCTAssertNoDifference(elements, expectedElements)
    }

    func test_noDependencies() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    pbxProjEscapedName: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                ),
                dependencies: []
            ),
            .mock(
                key: ["C"],
                identifier: .init(
                    pbxProjEscapedName: "C",
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

        let createContainerItemProxyElement =
            Generator.CreateContainerItemProxyElement.mock(
                elements: [
                    Element(identifier: "CIP_AB_ID", content: "{CIP_AB}"),
                    Element(identifier: "CIP_C_ID", content: "{CIP_C}"),
                ]
            )
        let createTargetDependencyElement =
            Generator.CreateTargetDependencyElement.mock(
                elements: [
                    Element(identifier: "TD_AB_ID", content: "{TD_AB}"),
                    Element(identifier: "TD_C_ID", content: "{TD_C}"),
                ]
            )

        let expectedCreateContainerItemProxyElementCalled: [
            Generator.CreateContainerItemProxyElement.MockTracker.Called
        ] = [
            .init(
                subIdentifier: identifiers["A"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
            .init(
                subIdentifier: identifiers["C"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
        ]
        let expectedCreateTargetDependencyElementCalled: [
            Generator.CreateTargetDependencyElement.MockTracker.Called
        ] = [
            .init(
                subIdentifier: identifiers["A"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_AB_ID"
            ),
            .init(
                subIdentifier: identifiers["C"]!.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_C_ID"
            ),
        ]

        let expectedElements: [Element] = [
            .init(identifier: "CIP_AB_ID", content: "{CIP_AB}"),
            .init(identifier: "TD_AB_ID", content: "{TD_AB}"),
            .init(identifier: "CIP_C_ID", content: "{CIP_C}"),
            .init(identifier: "TD_C_ID", content: "{TD_C}"),
        ]

        // Act

        let elements = try Generator.CreateDependencyElements
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers,
                createContainerItemProxyElement:
                    createContainerItemProxyElement.mock,
                createTargetDependencyElement:
                    createTargetDependencyElement.mock
            )

        // Assert

        XCTAssertNoDifference(
            createContainerItemProxyElement.tracker.called,
            expectedCreateContainerItemProxyElementCalled
        )
        XCTAssertNoDifference(
            createTargetDependencyElement.tracker.called,
            expectedCreateTargetDependencyElementCalled
        )
        XCTAssertNoDifference(elements, expectedElements)
    }
}
