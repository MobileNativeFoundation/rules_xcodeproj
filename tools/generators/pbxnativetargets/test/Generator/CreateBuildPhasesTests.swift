import CustomDump
import XCTest

@testable import PBXProj
@testable import pbxnativetargets

final class CreateBuildPhasesTests: XCTestCase {
    func test_synchronizedFolderOnlyTarget_doesNotCreateCompileStub() {
        let consolidatedInputs = Target.ConsolidatedInputs(
            srcs: [],
            nonArcSrcs: []
        )
        let identifier = Identifiers.Targets.id(
            subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"),
            name: "App"
        )

        var capturedHasCompileStub: Bool?
        var capturedSourcesIdentifiers: [String]?

        let result = Generator.CreateBuildPhases.defaultCallable(
            consolidatedInputs: consolidatedInputs,
            hasSourceInputs: true,
            hasCParams: false,
            hasCxxParams: false,
            hasLinkParams: true,
            identifier: identifier,
            productType: .application,
            shard: 0xA,
            usesInfoPlist: true,
            watchKitExtensionProductIdentifier: nil,
            createBazelIntegrationBuildPhaseObject: .init(callable: { _, _, _ in
                nil
            }),
            createBuildFileSubIdentifier: .init(callable: { _, _, _, _ in
                XCTFail("expected no explicit source build files")
                return .init(shard: "UNUSED", type: .source, path: "unused", hash: "UNUSED")
            }),
            createCreateCompileDependenciesBuildPhaseObject: .init(callable: { _, _, _ in
                nil
            }),
            createCreateLinkDependenciesBuildPhaseObject: .init(callable: { subIdentifier, hasCompileStub in
                capturedHasCompileStub = hasCompileStub
                return Object(
                    identifier: "\(subIdentifier.shard)LINK",
                    content: "link"
                )
            }),
            createEmbedAppExtensionsBuildPhaseObject: .init(callable: { _, _ in
                XCTFail("unexpected watchkit embed phase")
                return Object(identifier: "UNUSED", content: "unused")
            }),
            createProductBuildFileObject: .init(callable: { _, _ in
                XCTFail("unexpected product build file")
                return Object(identifier: "UNUSED", content: "unused")
            }),
            createSourcesBuildPhaseObject: .init(callable: { subIdentifier, buildFileIdentifiers in
                capturedSourcesIdentifiers = buildFileIdentifiers
                return Object(
                    identifier: "\(subIdentifier.shard)SOURCES",
                    content: "sources"
                )
            })
        )

        XCTAssertEqual(capturedHasCompileStub, false)
        XCTAssertNoDifference(capturedSourcesIdentifiers, [])
        XCTAssertTrue(result.buildFileSubIdentifiers.isEmpty)
        XCTAssertEqual(result.buildPhases.count, 2)
        XCTAssertTrue(result.buildFileObjects.isEmpty)
    }
}
