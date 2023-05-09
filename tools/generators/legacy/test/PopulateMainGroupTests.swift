import CustomDump
import XcodeProj
import XCTest

@testable import generator

final class PopulateMainGroupTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let mainGroup = pbxProj.rootObject!.mainGroup!
        let willBeRemoved = PBXFileReference(name: "Will Be Removed")
        mainGroup.addChild(willBeRemoved)
        pbxProj.add(object: mainGroup)

        let rootElements: [PBXFileElement] = [
            PBXFileReference(name: "Z"),
            PBXGroup(name: "A"),
            PBXFileReference(name: "X"),
        ]
        rootElements.forEach { pbxProj.add(object: $0) }

        let productsGroup = PBXGroup(name: "P")
        pbxProj.add(object: productsGroup)

        let children: [PBXFileElement] = [
            PBXFileReference(name: "Z"),
            PBXGroup(name: "A"),
            PBXFileReference(name: "X"),
            PBXGroup(name: "P"),
            PBXGroup(sourceTree: .group, name: "Frameworks"),
        ]
        children.forEach { expectedPBXProj.add(object: $0) }
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!
        expectedMainGroup.addChildren(children)

        // Act

        Generator.populateMainGroup(
            mainGroup,
            in: pbxProj,
            rootElements: rootElements,
            productsGroup: productsGroup
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(mainGroup, expectedMainGroup)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
