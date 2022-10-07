import XcodeProj
import XCTest

@testable import generator

extension XCSchemeInfoVariableExpansionContextInfoTests {
    func test_hostResolution_none() throws {
        let contextInfo = try XCSchemeInfo.VariableExpansionContextInfo(
            resolveHostsFor: .none,
            topLevelTargetInfos: []
        )
        XCTAssertEqual(contextInfo, .none)
    }

    func test_hostResolution_target() throws {
        let contextInfo = try XCSchemeInfo.VariableExpansionContextInfo(
            resolveHostsFor: .target(unitTestTargetInfo),
            topLevelTargetInfos: []
        )
        guard case let .target(targetInfo) = contextInfo else {
            XCTFail("Expeted `target`.")
            return
        }
        XCTAssertNotEqual(targetInfo.hostResolution, .unresolved)
    }
}

extension XCSchemeInfoVariableExpansionContextInfoTests {
    func test_customSchemeInit_none() throws {
        let contextInfo = try XCSchemeInfo.VariableExpansionContextInfo(
            context: .none,
            targetResolver: targetResolver,
            targetIDsByLabel: [:]
        )
        let expected = XCSchemeInfo.VariableExpansionContextInfo.none
        XCTAssertEqual(contextInfo, expected)
    }

    func test_customSchemeInit_target() throws {
        let contextInfo = try XCSchemeInfo.VariableExpansionContextInfo(
            context: .target(unitTestTarget.label),
            targetResolver: targetResolver,
            targetIDsByLabel: [unitTestTarget.label: unitTestTargetID]
        )
        let expected = XCSchemeInfo.VariableExpansionContextInfo.target(
            unitTestTargetInfo
        )
        XCTAssertEqual(contextInfo, expected)
    }
}

extension XCSchemeInfoVariableExpansionContextInfoTests {
    func test_targetInfo() {
        // given
        let contextInfo = XCSchemeInfo.VariableExpansionContextInfo
            .target(unitTestTargetInfo)

        // then
        XCTAssertEqual(contextInfo.targetInfo, unitTestTargetInfo)
    }

    func test_targetInfo_none() {
        // given
        let contextInfo = XCSchemeInfo.VariableExpansionContextInfo.none

        // then
        XCTAssertEqual(contextInfo.targetInfo, .none)
    }
}

// swiftlint:disable:next type_name
class XCSchemeInfoVariableExpansionContextInfoTests: XCTestCase {
    let directories = FilePathResolver.Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        external: "/some/bazel72/external",
        bazelOut: "/some/bazel72/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        bazelIntegration: "bazel",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )
    lazy var filePathResolver = FilePathResolver(
        directories: directories
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )

    lazy var pbxTargetsDict = targetResolver.pbxTargets

    let unitTestTargetID = TargetID("B 2")

    lazy var unitTestTarget = Fixtures.targets[unitTestTargetID]!

    lazy var unitTestPBXTarget = pbxTargetsDict["B 2"]!

    // swiftlint:disable:next force_try
    lazy var unitTestTargetInfo = try! targetResolver.targetInfo(targetID: "B 2")
}
