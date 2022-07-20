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

    func test_init_hostResolution_noHosts_withoutTopLevelTargets() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_init_hostResolution_withHosts_withoutTopLevelTargets() throws {
        let appHostInfo = XCSchemeInfo.HostInfo(
            pbxTarget: appTarget,
            referencedContainer: filePathResolver.containerReference,
            index: 0
        )
        let unitTestHostInfo = XCSchemeInfo.HostInfo(
            pbxTarget: unitTestTarget,
            referencedContainer: filePathResolver.containerReference,
            index: 1
        )
        let targetInfo = XCSchemeInfo.TargetInfo(
            pbxTarget: libraryTarget,
            referencedContainer: filePathResolver.containerReference,
            hostInfos: [appHostInfo, unitTestHostInfo],
            extensionPointIdentifiers: []
        )
        XCTAssertNil(targetInfo.selectedHostInfo)

        let resolvedTargetInfo = XCSchemeInfo.TargetInfo(
            resolveHostFor: targetInfo,
            topLevelTargetInfos: []
        )
        XCTAssertEqual(resolvedTargetInfo.selectedHostInfo, appHostInfo)
    }

    func test_init_hostResolution_withHosts_withTopLevelTargets() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_buildableReferences() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_bazelBuildPreActions() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_productType() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_buildableReferences() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
    func test_Sequence_buildActionEntries() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

extension XCSchemeInfoTargetInfoTests {
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
    lazy var appTarget = pbxTargetsDict["A 2"]!
    lazy var unitTestTarget = pbxTargetsDict["B 2"]!

    lazy var appTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: appTarget,
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
    lazy var libraryTargetInfo = XCSchemeInfo.TargetInfo(
        pbxTarget: libraryTarget,
        referencedContainer: filePathResolver.containerReference,
        hostInfos: [],
        extensionPointIdentifiers: []
    )
    // lazy var libraryTargetInfoWithHost = XCSchemeInfo.TargetInfo(
    //     resolveHostFor: .init(
    //         pbxTarget: libraryTarget,
    //         referencedContainer: filePathResolver.containerReference,
    //         hostInfos: [
    //             .init(pbxTarget: appTarget, referencedContainer: filePathResolver.containerReference),
    //         ],
    //         extensionPointIdentifiers: []
    //     ),
    //     topLevelTargetInfos: []
    // )
}
