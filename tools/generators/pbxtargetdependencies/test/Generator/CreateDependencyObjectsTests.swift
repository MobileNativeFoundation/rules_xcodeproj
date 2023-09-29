import CustomDump
import OrderedCollections
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class CreateDependencyObjectsTests: XCTestCase {
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
        let identifiedTargetsMap: OrderedDictionary<
            TargetID,
            IdentifiedTarget
        > = [
            "A": identifiedTargets[0],
            "B": identifiedTargets[0],
            "C": identifiedTargets[1],
        ]

        let createContainerItemProxyObject =
            Generator.CreateContainerItemProxyObject.mock(
                objects: [
                    .init(identifier: "CIP_AB1_ID", content: "{CIP_AB1}"),
                    .init(identifier: "CIP_AB2_ID", content: "{CIP_AB2}"),
                    .init(identifier: "CIP_C_ID", content: "{CIP_C}"),
                ]
            )
        let createTargetDependencyObject =
            Generator.CreateTargetDependencyObject.mock(
                objects: [
                    .init(identifier: "TD_AB1_ID", content: "{TD_AB1}"),
                    .init(identifier: "TD_AB2_ID", content: "{TD_AB2}"),
                    .init(identifier: "TD_C_ID", content: "{TD_C}"),
                ]
            )

        let expectedCreateContainerItemProxyObjectCalled: [
            Generator.CreateContainerItemProxyObject.MockTracker.Called
        ] = [
            .init(
                subIdentifier:
                    identifiedTargetsMap["A"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
            .init(
                subIdentifier:
                    identifiedTargetsMap["A"]!.identifier.subIdentifier,
                dependencyIdentifier: identifiedTargetsMap["C"]!.identifier
            ),
            .init(
                subIdentifier:
                    identifiedTargetsMap["C"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
        ]
        let expectedCreateTargetDependencyObjectCalled: [
            Generator.CreateTargetDependencyObject.MockTracker.Called
        ] = [
            .init(
                subIdentifier:
                    identifiedTargetsMap["A"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_AB1_ID"
            ),
            .init(
                subIdentifier:
                    identifiedTargetsMap["A"]!.identifier.subIdentifier,
                dependencyIdentifier: identifiedTargets[1].identifier,
                containerItemProxyIdentifier: "CIP_AB2_ID"
            ),
            .init(
                subIdentifier:
                    identifiedTargetsMap["C"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_C_ID"
            ),
        ]

        let expectedObjects: [Object] = [
            .init(identifier: "CIP_AB1_ID", content: "{CIP_AB1}"),
            .init(identifier: "TD_AB1_ID", content: "{TD_AB1}"),
            .init(identifier: "CIP_AB2_ID", content: "{CIP_AB2}"),
            .init(identifier: "TD_AB2_ID", content: "{TD_AB2}"),
            .init(identifier: "CIP_C_ID", content: "{CIP_C}"),
            .init(identifier: "TD_C_ID", content: "{TD_C}"),
        ]

        // Act

        let objects = try Generator.CreateDependencyObjects
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiedTargetsMap: identifiedTargetsMap,
                createContainerItemProxyObject:
                    createContainerItemProxyObject.mock,
                createTargetDependencyObject:
                    createTargetDependencyObject.mock
            )

        // Assert

        XCTAssertNoDifference(
            createContainerItemProxyObject.tracker.called,
            expectedCreateContainerItemProxyObjectCalled
        )
        XCTAssertNoDifference(
            createTargetDependencyObject.tracker.called,
            expectedCreateTargetDependencyObjectCalled
        )
        XCTAssertNoDifference(objects, expectedObjects)
    }

    func test_noDependencies() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
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
        ]
        let identifiedTargetsMap: OrderedDictionary<
            TargetID,
            IdentifiedTarget
        > = [
            "C": identifiedTargets[1],
            "A": identifiedTargets[0],
            "B": identifiedTargets[0],
        ]

        let createContainerItemProxyObject =
            Generator.CreateContainerItemProxyObject.mock(
                objects: [
                    .init(identifier: "CIP_AB_ID", content: "{CIP_AB}"),
                    .init(identifier: "CIP_C_ID", content: "{CIP_C}"),
                ]
            )
        let createTargetDependencyObject =
            Generator.CreateTargetDependencyObject.mock(
                objects: [
                    .init(identifier: "TD_AB_ID", content: "{TD_AB}"),
                    .init(identifier: "TD_C_ID", content: "{TD_C}"),
                ]
            )

        let expectedCreateContainerItemProxyObjectCalled: [
            Generator.CreateContainerItemProxyObject.MockTracker.Called
        ] = [
            .init(
                subIdentifier:
                    identifiedTargetsMap["A"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
            .init(
                subIdentifier:
                    identifiedTargetsMap["C"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies
            ),
        ]
        let expectedCreateTargetDependencyObjectCalled: [
            Generator.CreateTargetDependencyObject.MockTracker.Called
        ] = [
            .init(
                subIdentifier:
                    identifiedTargetsMap["A"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_AB_ID"
            ),
            .init(
                subIdentifier:
                    identifiedTargetsMap["C"]!.identifier.subIdentifier,
                dependencyIdentifier: .bazelDependencies,
                containerItemProxyIdentifier: "CIP_C_ID"
            ),
        ]

        let expectedObjects: [Object] = [
            .init(identifier: "CIP_AB_ID", content: "{CIP_AB}"),
            .init(identifier: "TD_AB_ID", content: "{TD_AB}"),
            .init(identifier: "CIP_C_ID", content: "{CIP_C}"),
            .init(identifier: "TD_C_ID", content: "{TD_C}"),
        ]

        // Act

        let objects = try Generator.CreateDependencyObjects
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiedTargetsMap: identifiedTargetsMap,
                createContainerItemProxyObject:
                    createContainerItemProxyObject.mock,
                createTargetDependencyObject:
                    createTargetDependencyObject.mock
            )

        // Assert

        XCTAssertNoDifference(
            createContainerItemProxyObject.tracker.called,
            expectedCreateContainerItemProxyObjectCalled
        )
        XCTAssertNoDifference(
            createTargetDependencyObject.tracker.called,
            expectedCreateTargetDependencyObjectCalled
        )
        XCTAssertNoDifference(objects, expectedObjects)
    }
}
