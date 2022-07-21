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
        productName: "MyChicken",
        product: productFileReference
    )

    let pbxTargetWithoutProduct = PBXTarget(
        name: "chicken",
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
        pbxTarget.name = "//examples/chicken:smidgen"
        XCTAssertEqual(
            pbxTarget.schemeName,
            "__examples_chicken_smidgen"
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

    func test_defaultBuildConfigurationName_withBuildConfigurationList() throws {
        let configurationName = "Foo"
        let xcBuildConfig = XCBuildConfiguration(name: configurationName)
        let xcConfigList = XCConfigurationList(
            buildConfigurations: [xcBuildConfig]
        )
        pbxTarget.buildConfigurationList = xcConfigList
        XCTAssertEqual(pbxTarget.defaultBuildConfigurationName, configurationName)
    }

    func test_defaultBuildConfigurationName_withoutBuildConfigurationList() throws {
        XCTAssertEqual(pbxTarget.defaultBuildConfigurationName, "Debug")
    }
}
