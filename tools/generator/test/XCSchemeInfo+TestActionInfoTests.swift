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
            XCTFail("Expected `PreconditionError`")
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
            XCTFail("Expected `PreconditionError`")
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
            XCTFail("Expected a `TestActionInfo`")
            return
        }
        XCTAssertEqual(testActionInfo.buildConfigurationName, buildConfigurationName)
        for targetInfo in testActionInfo.targetInfos {
            XCTAssertNotEqual(targetInfo.hostResolution, .unresolved)
        }
    }
}

// MARK: - Custom Scheme Initializer Tests

extension XCSchemeInfoTestActionInfoTests {
    func test_customSchemeInit_noTestAction() throws {
        let actual = try XCSchemeInfo.TestActionInfo(
            testAction: nil,
            targetResolver: targetResolver,
            targetIDsByLabel: [:]
        )
        XCTAssertNil(actual)
    }

    func test_customSchemeInit_withTestAction() throws {
        let actual = try XCSchemeInfo.TestActionInfo(
            testAction: xcodeScheme.testAction,
            targetResolver: targetResolver,
            targetIDsByLabel: try xcodeScheme.resolveTargetIDs(targets: targetResolver.targets)
        )
        let expected = try XCSchemeInfo.TestActionInfo(
            buildConfigurationName: .defaultBuildConfigurationName,
            targetInfos: [try targetResolver.targetInfo(targetID: "B 2")]
        )
        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Test Data

class XCSchemeInfoTestActionInfoTests: XCTestCase {
    let buildConfigurationName = "Foo"

    lazy var filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )

    lazy var pbxTargetsDict = targetResolver.pbxTargets

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

    lazy var xcodeScheme = XcodeScheme(
        name: "My Scheme",
        testAction: .init(targets: [targetResolver.targets["B 2"]!.label])
    )
}
