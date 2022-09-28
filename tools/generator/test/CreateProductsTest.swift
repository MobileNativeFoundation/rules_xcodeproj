import CustomDump
import XCTest

@testable import generator

final class CreateProductsTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedPBXProject = expectedPBXProj.rootObject!
        let expectedMainGroup = expectedPBXProject.mainGroup!

        let consolidatedTargets = Fixtures.consolidatedTargets

        let expectedProducts = Fixtures.products(in: expectedPBXProj)

        let expectedProductsGroup = Fixtures.productsGroup(
            in: expectedPBXProj,
            products: expectedProducts
        )
        expectedPBXProject.productsGroup = expectedProductsGroup
        expectedMainGroup.addChild(expectedProductsGroup)

        // Act

        let (createdProducts, createdProductsGroup) = Generator.createProducts(
            in: pbxProj,
            for: consolidatedTargets
        )

        // We need to add the products group to a group to allow references to
        // become fixed
        mainGroup.addChild(createdProductsGroup)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(
            createdProducts.byFilePath.map(KeyAndValue.init).sorted(),
            expectedProducts.byFilePath.map(KeyAndValue.init).sorted()
        )
        XCTAssertNoDifference(
            createdProducts.byTarget.map(KeyAndValue.init).sorted(),
            expectedProducts.byTarget.map(KeyAndValue.init).sorted()
        )
        XCTAssertNoDifference(createdProductsGroup, expectedProductsGroup)

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
