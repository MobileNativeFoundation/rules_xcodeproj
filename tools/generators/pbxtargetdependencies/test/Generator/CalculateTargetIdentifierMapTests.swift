import CustomDump
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class CalculateTargetIdentifierMapTests: XCTestCase {
    func test() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    pbxProjEscapedName: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                )
            ),
            .mock(
                key: ["C"],
                identifier: .init(
                    pbxProjEscapedName: "C",
                    subIdentifier: .init(shard: "00", hash: "12345678"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                )
            ),
        ]

        let expectedMap: [TargetID: Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
            "B": identifiedTargets[0].identifier,
            "C": identifiedTargets[1].identifier,
        ]

        // Act

        let map = Generator.CalculateTargetIdentifierMap
            .defaultCallable(identifiedTargets: identifiedTargets)

        // Assert

        XCTAssertNoDifference(map, expectedMap)
    }
}
