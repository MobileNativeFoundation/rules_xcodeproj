import XcodeProj
import XCTest

@testable import generator

// MARK: XCScheme.PBXTargetInfo Tests

extension XCSchemeExtensionsTests {
    func test_PBXTargetInfo_init() throws {
        XCTAssertEqual(libraryTargetInfo.pbxTarget.name, libraryTarget.name)
        XCTAssertEqual(libraryTargetInfo.buildableReference, .init(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference
        ))
    }
}

// MARK: XCScheme.BuildableReference

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

// MARK: XCScheme.BuildAction

extension XCSchemeExtensionsTests {
    func test_BuildAction_init_buildModeBazel_noHost() throws {
        let targetInfos = [libraryTargetInfo, anotherLibraryTargetInfo]
        let buildAction = XCScheme.BuildAction(
            buildMode: .bazel,
            targetInfos: targetInfos,
            hostBuildableReference: nil,
            hostIndex: nil
        )
        let expected = XCScheme.BuildAction(
            buildActionEntries: targetInfos
                .map(\.buildableReference)
                .map { .init(withDefaults: $0) },
            preActions: [.initBazelBuildOutputGroupsFile] +
                targetInfos.compactMap { .init(targetInfo: $0, hostIndex: nil) },
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
    }

    func test_BuildAction_init_buildModeBazel_withHost() throws {
        let targetInfos = [libraryTargetInfo, anotherLibraryTargetInfo]
        let hostTargetInfo = appTargetInfo
        let hostIndex = 1
        let buildAction = XCScheme.BuildAction(
            buildMode: .bazel,
            targetInfos: targetInfos,
            hostBuildableReference: hostTargetInfo.buildableReference,
            hostIndex: hostIndex
        )
        let expected = XCScheme.BuildAction(
            buildActionEntries: (targetInfos + [hostTargetInfo])
                .map(\.buildableReference)
                .map { .init(withDefaults: $0) },
            preActions: [.initBazelBuildOutputGroupsFile] +
                targetInfos.compactMap { .init(targetInfo: $0, hostIndex: hostIndex) },
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
    }

    func test_BuildAction_init_buildModeXcode_noHost() throws {
        let targetInfos = [libraryTargetInfo, anotherLibraryTargetInfo]
        let buildAction = XCScheme.BuildAction(
            buildMode: .xcode,
            targetInfos: targetInfos,
            hostBuildableReference: nil,
            hostIndex: nil
        )
        let expected = XCScheme.BuildAction(
            buildActionEntries: targetInfos
                .map(\.buildableReference)
                .map { .init(withDefaults: $0) },
            preActions: [],
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        XCTAssertEqual(buildAction, expected)
    }
}

// MARK: XCScheme.BuildAction.Entry

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

// MARK: XCScheme.ExecutionAction

extension XCSchemeExtensionsTests {
    func test_ExecutionAction_withNativeTarget_noHostIndex() throws {
        let actual = XCScheme.ExecutionAction(targetInfo: libraryTargetInfo, hostIndex: nil)
        guard let action = actual else {
            XCTFail("Expected an action")
            return
        }
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
        let actual = XCScheme.ExecutionAction(targetInfo: libraryTargetInfo, hostIndex: hostIndex)
        guard let action = actual else {
            XCTFail("Expected an action")
            return
        }
        XCTAssertEqual(
            action.title,
            "Set Bazel Build Output Groups for \(libraryTargetInfo.pbxTarget.name)"
        )
        XCTAssertEqual(action.environmentBuildable, libraryTargetInfo.buildableReference)
        XCTAssertTrue(action.scriptText.contains("$BAZEL_TARGET_ID"))
        XCTAssertTrue(action.scriptText.contains("$BAZEL_HOST_TARGET_ID_\(hostIndex)"))
    }

    func test_ExecutionAction_withNonNativeTarget() throws {
        let pbxTarget = PBXTarget(name: "Foo")
        let targetInfo = XCScheme.PBXTargetInfo(
            pbxTarget: pbxTarget,
            referencedContainer: filePathResolver.containerReference
        )
        let actual = XCScheme.ExecutionAction(targetInfo: targetInfo, hostIndex: nil)
        XCTAssertNil(actual)
    }
}

// MARK: Test Data

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

    lazy var libraryTargetInfo = XCScheme.PBXTargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference
    )
    lazy var anotherLibraryTargetInfo = XCScheme.PBXTargetInfo(
        pbxTarget: anotherLibraryTarget,
        referencedContainer: filePathResolver.containerReference
    )
    lazy var appTargetInfo = XCScheme.PBXTargetInfo(
        pbxTarget: appTarget,
        referencedContainer: filePathResolver.containerReference
    )
}
