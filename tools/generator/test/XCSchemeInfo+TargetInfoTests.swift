import XcodeProj
import XCTest

@testable import generator

// MARK: XCSchemeInfo.TargetInfo Tests

extension XCSchemeInfoTargetInfoTests {
    func test_init() throws {
        XCTAssertEqual(libraryTargetInfo.pbxTarget.name, libraryTarget.name)
        XCTAssertEqual(libraryTargetInfo.buildableReference, .init(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference
        ))
    }

    func test_bazelBuildPreActions() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_productType() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_Sequence_buildableReferences() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_Sequence_buildActionEntries() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_Sequence_bazelBuildPreActions() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

// MARK: Test Data

class XCSchemeInfoTargetInfoTests: XCTestCase {
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

    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
}
