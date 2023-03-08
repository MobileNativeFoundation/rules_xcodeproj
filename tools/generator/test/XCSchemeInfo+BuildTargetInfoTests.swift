import XcodeProj
import XCTest

@testable import generator

// MARK: - Sequence buildActionEntries Tests

extension XCSchemeInfoBuildTargetInfoTests {
    func test_Sequence_buildActionEntries() throws {
        let buildTargetInfos = [libraryTargetInfo, appTargetInfo]
            .map { XCSchemeInfo.BuildTargetInfo(targetInfo: $0, buildFor: .allEnabled) }
        let expected: [XCScheme.BuildAction.Entry] = [
            libraryTargetInfo.buildableReference,
            appTargetInfo.buildableReference,
        ].map { .init(buildableReference: $0, buildFor: .default) }
        XCTAssertEqual(try buildTargetInfos.buildActionEntries, expected)
    }
}

// MARK: Test Data

class XCSchemeInfoBuildTargetInfoTests: XCTestCase {
    let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "examples/foo/Foo.xcodeproj"
    )

    // We must retain in order to retain some sub-objects (like
    // `XCConfigurationList`)
    private let pbxProj = Fixtures.pbxProj()

    lazy var targetResolver = Fixtures.targetResolver(
        pbxProj: pbxProj,
        directories: directories,
        referencedContainer: directories.containerReference
    )

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTargetInfo: targetResolver.pbxTargetInfos["A 2"]!,
            hostInfos: []
        ),
        topLevelTargetInfos: []
    )
    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        resolveHostFor: .init(
            pbxTargetInfo: targetResolver.pbxTargetInfos["A 1"]!,
            hostInfos: []
        ),
        topLevelTargetInfos: []
    )
}
