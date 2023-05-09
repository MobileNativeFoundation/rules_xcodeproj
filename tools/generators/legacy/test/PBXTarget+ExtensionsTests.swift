import XcodeProj
import XCTest

@testable import generator

class PBXTargetExtensionsTests: XCTestCase {
    // Need to create the PBXFileReference separate from the PBXTarget
    // initializer, so that the file reference initializes properly.
    // If you inline the construction of the file reference the
    // product properties will not initialize properly.
    let productFileReference = PBXFileReference(
        path: "MyChicken.app"
    )
    lazy var pbxTarget = PBXTarget(
        name: "chicken",
        buildConfigurationList: buildConfigurationList,
        productName: "MyChicken",
        product: productFileReference
    )

    let buildConfiguration = XCBuildConfiguration(name: "Foo")

    lazy var buildConfigurationList = XCConfigurationList(
        buildConfigurations: [buildConfiguration],
        defaultConfigurationName: buildConfiguration.name
    )

    lazy var pbxTargetWithoutProduct = PBXTarget(
        name: "chicken",
        buildConfigurationList: buildConfigurationList,
        productName: "MyChicken"
    )

    func test_getBuildableName_withProductPath() {
        let buildableName = pbxTarget.buildableName
        XCTAssertEqual(buildableName, "MyChicken.app")
    }

    func test_getBuildableName_withoutProductPath() {
        pbxTarget.product = nil
        let buildableName = pbxTargetWithoutProduct.buildableName
        XCTAssertEqual(buildableName, "chicken")
    }

    func test_getSchemeName_withSlashesInBuildableName() throws {
        pbxTarget.name = "@//examples/chicken:smidgen"
        XCTAssertEqual(
            pbxTarget.schemeName,
            "@__examples_chicken_smidgen"
        )
    }

    func test_schemeName_withoutSlashesInBuildableName() throws {
        XCTAssertEqual(pbxTarget.schemeName, "chicken")
    }

    func test_isTestable_withoutProductType() throws {
        XCTAssertFalse(pbxTarget.isTestable)
    }

    func test_isTestable_whenIsTestBundle() throws {
        pbxTarget.productType = .unitTestBundle
        XCTAssertTrue(pbxTarget.isTestable)
    }

    func test_isTestable_whenNotIsTestBundle() throws {
        pbxTarget.productType = .application
        XCTAssertFalse(pbxTarget.isTestable)
    }

    func test_isLaunchable_withoutProductType() throws {
        XCTAssertFalse(pbxTarget.isLaunchable)
    }

    func test_isLaunchable_whenIsExecutable() throws {
        pbxTarget.productType = .application
        XCTAssertTrue(pbxTarget.isLaunchable)
    }

    func test_isLaunchable_whenNotIsExecutable() throws {
        pbxTarget.productType = .staticLibrary
        XCTAssertFalse(pbxTarget.isLaunchable)
    }

    func test_defaultBuildConfigurationName() throws {
        XCTAssertEqual(pbxTarget.defaultBuildConfigurationName, "Foo")
    }
}
