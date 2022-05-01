import XcodeProj
import XCTest

@testable import generator

class PBXTargetExtensionsTests: XCTestCase {
    let pbxTarget = PBXTarget(name: "chicken", productName: "MyChicken")

    func test_buildableName_WithProductName() throws {
        XCTAssertEqual(pbxTarget.buildableName, "MyChicken")
    }

    func test_buildableName_WithoutProductName() throws {
        pbxTarget.productName = nil
        XCTAssertEqual(pbxTarget.buildableName, "chicken")
    }

    func test_createBuildableReference() throws {
        let referencedContainer: XcodeProjContainerReference =
            "container:Foo.xcodeproj"
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

    func test_schemeName_WithSlashesInBuildableName() throws {
        pbxTarget.name = "//examples/chicken:smidgen"
        pbxTarget.productName = nil
        XCTAssertEqual(pbxTarget.schemeName, "__examples_chicken:smidgen")
    }

    func test_schemeName_WithoutSlashesInBuildableName() throws {
        XCTAssertEqual(pbxTarget.schemeName, "MyChicken")
    }

    func test_isTestable_WithoutProductType() throws {
        XCTAssertFalse(pbxTarget.isTestable)
    }

    func test_isTestable_WhenIsTestBundle() throws {
        pbxTarget.productType = .unitTestBundle
        XCTAssertTrue(pbxTarget.isTestable)
    }

    func test_isTestable_WhenNotIsTestBundle() throws {
        pbxTarget.productType = .application
        XCTAssertFalse(pbxTarget.isTestable)
    }

    func test_isLaunchable_WithoutProductType() throws {
        XCTAssertFalse(pbxTarget.isLaunchable)
    }

    func test_isLaunchable_WhenIsExecutable() throws {
        pbxTarget.productType = .application
        XCTAssertTrue(pbxTarget.isLaunchable)
    }

    func test_isLaunchable_WhenNotIsExecutable() throws {
        pbxTarget.productType = .staticLibrary
        XCTAssertFalse(pbxTarget.isLaunchable)
    }

    func test_defaultBuildConfigurationName_WithBuildConfigurationList() throws {
        let configurationName = "Foo"
        let xcBuildConfig = XCBuildConfiguration(name: configurationName)
        let xcConfigList = XCConfigurationList(
            buildConfigurations: [xcBuildConfig]
        )
        pbxTarget.buildConfigurationList = xcConfigList
        XCTAssertEqual(pbxTarget.defaultBuildConfigurationName, configurationName)
    }

    func test_defaultBuildConfigurationName_WithoutBuildConfigurationList() throws {
        XCTAssertEqual(pbxTarget.defaultBuildConfigurationName, "Debug")
    }
}
