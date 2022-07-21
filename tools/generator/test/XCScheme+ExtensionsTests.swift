import XcodeProj
import XCTest

@testable import generator

// MARK: - XCScheme.BuildableReference Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildableReference_init() throws {
        let buildableReference = XCScheme.BuildableReference(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference
        )
        let expected = XCScheme.BuildableReference(
            referencedContainer: filePathResolver.containerReference,
            blueprint: libraryTarget,
            buildableName: libraryTarget.buildableName,
            blueprintName: libraryTarget.name
        )
        XCTAssertEqual(buildableReference, expected)
    }
}

// MARK: - XCScheme.BuildAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildAction_init_buildModeBazel() throws {
        let buildAction = try XCScheme.BuildAction(
            buildMode: .bazel,
            buildActionInfo: buildActionInfo
        )
        let expected = XCScheme.BuildAction(
            buildActionEntries: buildActionInfo.targetInfos.buildActionEntries,
            preActions: try buildActionInfo.targetInfos.bazelBuildPreActions,
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
    }

    func test_BuildAction_init_buildModeXcode() throws {
        let buildAction = try XCScheme.BuildAction(
            buildMode: .xcode,
            buildActionInfo: buildActionInfo
        )
        let expected = XCScheme.BuildAction(
            buildActionEntries: buildActionInfo.targetInfos.buildActionEntries,
            preActions: [],
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
    }
}

// MARK: - XCScheme.BuildAction.Entry Initializer Tests

extension XCSchemeExtensionsTests {
    func test_BuildAction_Entry_init() throws {
        let entry = XCScheme.BuildAction.Entry(withDefaults: libraryTargetInfo.buildableReference)
        let expected = XCScheme.BuildAction.Entry(
            buildableReference: libraryTargetInfo.buildableReference,
            buildFor: [
                .running,
                .testing,
                .profiling,
                .archiving,
                .analyzing,
            ]
        )
        XCTAssertEqual(entry, expected)
    }
}

// MARK: - XCScheme.ExecutionAction Initializer Tests

extension XCSchemeExtensionsTests {
    func test_ExecutionAction_withNativeTarget_noHostIndex() throws {
        let action = XCScheme.ExecutionAction(
            bazelBuildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: nil
        )
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertFalse(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_"))
    }

    func test_ExecutionAction_withNativeTarget_withHostIndex() throws {
        let hostIndex = 1
        let action = XCScheme.ExecutionAction(
            bazelBuildFor: libraryTargetInfo.buildableReference,
            name: libraryTargetInfo.pbxTarget.name,
            hostIndex: hostIndex
        )
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertTrue(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_\(hostIndex)"))
    }
}

// MARK: - Test Data

class XCSchemeExtensionsTests: XCTestCase {
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
    lazy var anotherLibraryTarget = pbxTargetsDict["C 1"]!
    lazy var appTarget = pbxTargetsDict["A 2"]!

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var anotherLibraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: anotherLibraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )

    // swiftlint:disable:next force_try
    lazy var buildActionInfo = try! XCSchemeInfo.BuildActionInfo(
        resolveHostsFor: .init(
            targetInfos: [libraryTargetInfo, anotherLibraryTargetInfo]
        ),
        topLevelTargetInfos: []
    )!
}
