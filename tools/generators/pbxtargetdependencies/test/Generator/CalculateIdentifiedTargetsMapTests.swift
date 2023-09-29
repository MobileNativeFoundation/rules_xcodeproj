import CustomDump
import OrderedCollections
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class CalculateIdentifiedTargetsMapTests: XCTestCase {
    func test() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["C"],
                identifier: .init(
                    pbxProjEscapedName: "C",
                    subIdentifier: .init(shard: "00", hash: "12345678"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                )
            ),
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    pbxProjEscapedName: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                )
            ),
        ]

        let expectedMap: OrderedDictionary<TargetID, IdentifiedTarget> = [
            "C": identifiedTargets[0],
            "A": identifiedTargets[1],
            "B": identifiedTargets[1],
        ]

        // Act

        let map = Generator.CalculateIdentifiedTargetsMap
            .defaultCallable(identifiedTargets: identifiedTargets)

        // Assert

        XCTAssertNoDifference(map, expectedMap)
    }
}
