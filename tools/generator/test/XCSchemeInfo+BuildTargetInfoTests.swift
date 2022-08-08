import XcodeProj
import XCTest

@testable import generator

// MARK: - Sequence buildActionEntries Tests

extension XCSchemeInfoBuildTargetInfoTests {
    func test_Sequence_buildActionEntries() throws {
        let buildTargetInfos = [libraryTargetInfo, appTargetInfo]
            .map { XCSchemeInfo.BuildTargetInfo(targetInfo: $0) }
        let expected: [XCScheme.BuildAction.Entry] = [
            libraryTargetInfo.buildableReference,
            appTargetInfo.buildableReference,
        ].map { .init(buildableReference: $0, buildFor: .default) }
        XCTAssertEqual(try buildTargetInfos.buildActionEntries, expected)
    }
}

// MARK: Test Data

class XCSchemeInfoBuildTargetInfoTests: XCTestCase {
    lazy var filePathResolver = FilePathResolver(
        externalDirectory: "/some/bazel4/external",
        bazelOutDirectory: "/some/bazel4/bazel-out",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
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
