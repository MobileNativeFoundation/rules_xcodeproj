import XcodeProj
import XCTest

@testable import generator

class PBXTargetExtensionsTests: XCTestCase {
    let pbxTarget = PBXTarget(name: "chicken", productName: "MyChicken")

    func test_buildableName_withProductName() throws {
        XCTAssertEqual(pbxTarget.buildableName, "MyChicken")
    }

    func test_buildableName_withoutProductName() throws {
        pbxTarget.productName = nil
        XCTAssertEqual(pbxTarget.buildableName, "chicken")
    }

    func test_createBuildableReference() throws {
        let referencedContainer = "container:Foo.xcodeproj"
        let buildableReference = pbxTarget.createBuildableReference(
            referencedContainer: referencedContainer
        )
        let expected = XCScheme.BuildableReference(
            referencedContainer: "\(referencedContainer)",
            blueprint: pbxTarget,
            buildableName: pbxTarget.buildableName,
            blueprintName: pbxTarget.name
        )
        XCTAssertEqual(buildableReference, expected)
    }

    func test_schemeName_withSlashesInBuildableName() throws {
        pbxTarget.name = "//examples/chicken:smidgen"
        pbxTarget.productName = nil
        XCTAssertEqual(pbxTarget.schemeName, "__examples_chicken:smidgen")
    }

    func test_schemeName_withoutSlashesInBuildableName() throws {
        XCTAssertEqual(pbxTarget.schemeName, "MyChicken")
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
