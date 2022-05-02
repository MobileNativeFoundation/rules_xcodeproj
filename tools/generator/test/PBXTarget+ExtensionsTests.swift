import XcodeProj
import XCTest

@testable import generator

class PBXTargetExtensionsTests: XCTestCase {
    let pbxTarget = PBXTarget(name: "chicken", productName: "MyChicken")

    func test_getBuildableName_withProductName() throws {
        let buildableName = try pbxTarget.getBuildableName()
        XCTAssertEqual(buildableName, "MyChicken")
    }

    func test_getBuildableName_withoutProductName() throws {
        pbxTarget.productName = nil
        XCTAssertThrowsError(try pbxTarget.getBuildableName()) { error in
            guard let preconditionError = error as? PreconditionError else {
                XCTFail(
                    "The thrown error was not a `PreconditionError`. \(error)"
                )
                return
            }
            XCTAssertEqual(
                preconditionError.message,
                "`productName` not set on target"
            )
        }
    }

    func test_createBuildableReference() throws {
        let referencedContainer = "container:Foo.xcodeproj"
        let buildableReference = try pbxTarget.createBuildableReference(
            referencedContainer: referencedContainer
        )
        let expected = XCScheme.BuildableReference(
            referencedContainer: "\(referencedContainer)",
            blueprint: pbxTarget,
            buildableName: try pbxTarget.getBuildableName(),
            blueprintName: pbxTarget.name
        )
        XCTAssertEqual(buildableReference, expected)
    }

    func test_getSchemeName_withSlashesInBuildableName() throws {
        pbxTarget.productName = "//examples/chicken:smidgen"
        XCTAssertEqual(
            try pbxTarget.getSchemeName(),
            "__examples_chicken:smidgen"
        )
    }

    func test_schemeName_withoutSlashesInBuildableName() throws {
        XCTAssertEqual(
            try pbxTarget.getSchemeName(),
            "MyChicken"
        )
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
