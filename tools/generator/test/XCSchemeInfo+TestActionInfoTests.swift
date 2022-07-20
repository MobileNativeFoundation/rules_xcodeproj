import XcodeProj
import XCTest

@testable import generator

extension XCSchemeInfoTestActionInfoTests {
    func test_init_withEmptyTargetInfos() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_init_withNoTestables() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_init_allIsWell() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTestActionInfoTests {
    func test_hostResolution() throws {
        let actionInfo = try XCSchemeInfo.TestActionInfo(
            resolveHostsFor: .init(
                buildConfigurationName: buildConfigurationName,
                targetInfos: [unitTestTargetInfo]
            ),
            topLevelTargetInfos: []
        )
        guard let testActionInfo = actionInfo else {
            XCTFail("Expected a TestActionInfo.")
            return
        }
        XCTAssertEqual(testActionInfo.buildConfigurationName, buildConfigurationName)
        for targetInfo in testActionInfo.targetInfos {
            XCTAssertNotEqual(targetInfo.hostResolution, .unresolved)
        }
    }
}

class XCSchemeInfoTestActionInfoTests: XCTestCase {
    let buildConfigurationName = "Foo"

    lazy var filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var pbxTargetsDict: [ConsolidatedTarget.Key: PBXTarget] =
        Fixtures.pbxTargets(
            in: Fixtures.pbxProj(),
            consolidatedTargets: Fixtures.consolidatedTargets
        )
        .0

    lazy var libraryTarget = pbxTargetsDict["A 1"]!
    lazy var unitTestTarget = pbxTargetsDict["B 2"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    lazy var unitTestTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: unitTestTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
}
