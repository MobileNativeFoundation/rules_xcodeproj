import XcodeProj
import XCTest

@testable import generator

// MARK: - Initializer Tests

extension XCSchemeInfoTestActionInfoTests {
    func test_init_withEmptyTargetInfos() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfos: []
        )) {
          thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected PreconditionError.")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo.TestActionInfo` should have at least one `XCSchemeInfo.TargetInfo`.
""")
    }

    func test_init_withNoTestables() throws {
        var thrown: Error?
        XCTAssertThrowsError(try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfos: [libraryTargetInfo]
        )) {
          thrown = $0
        }
        guard let preconditionError = thrown as? PreconditionError else {
            XCTFail("Expected PreconditionError.")
            return
        }
        XCTAssertEqual(preconditionError.message, """
An `XCSchemeInfo.TestActionInfo` should only contain testable `XCSchemeInfo.TargetInfo` values.
""")
    }

    func test_init_allIsWell() throws {
        let testActionInfo = try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: buildConfigurationName,
            targetInfos: [unitTestTargetInfo]
        )
        XCTAssertEqual(testActionInfo.buildConfigurationName, buildConfigurationName)
        XCTAssertEqual(testActionInfo.targetInfos, [unitTestTargetInfo])
    }
}

// MARK: - Host Resolution Tests

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
            XCTFail("Expected a `TestActionInfo`.")
            return
        }
        XCTAssertEqual(testActionInfo.buildConfigurationName, buildConfigurationName)
        for targetInfo in testActionInfo.targetInfos {
            XCTAssertNotEqual(targetInfo.hostResolution, .unresolved)
        }
    }
}

// MARK: - Test Data

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
