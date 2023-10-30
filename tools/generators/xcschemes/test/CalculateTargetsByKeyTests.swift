import CustomDump
import PBXProj
import XCTest

@testable import xcschemes

class CalculateTargetsByKeyTests: XCTestCase {
    func test() {
        // Arrange

        let targets: [Target] = [
            .mock(key: ["B"]),
            .mock(key: ["A", "C"]),
        ]

        let expectedTargetsByKey: [Target.Key: Target] = [
            ["B"]: targets[0],
            ["A", "C"]: targets[1],
        ]
        let expectedTargetsByID: [TargetID: Target] = [
            "B": targets[0],
            "A": targets[1],
            "C": targets[1],
        ]


        // Act

        let (targetsByKey, targetsByID) = Generator.CalculateTargetsByKey
            .defaultCallable(targets: targets)

        // Assert

        XCTAssertNoDifference(targetsByKey, expectedTargetsByKey)
        XCTAssertNoDifference(targetsByID, expectedTargetsByID)
    }
}
