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

        let targets = Fixtures.targets

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
            for: targets
        )

        // We need to add the products group to a group to allow references to
        // become fixed
        mainGroup.addChild(createdProductsGroup)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(
            createdProducts.byPath,
            expectedProducts.byPath
        )
        XCTAssertNoDifference(
            createdProducts.byTarget,
            expectedProducts.byTarget
        )
        XCTAssertNoDifference(createdProductsGroup, expectedProductsGroup)

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
