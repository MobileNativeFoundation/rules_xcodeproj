import ToolCommon
import XCTest
@testable import pbxnativetargets
@testable import PBXProj

class StaticLibraryPreviewLinkContractTests: XCTestCase {
    func test_staticLibraryUsesCreateLinkDependenciesAndLibtoolFlags() async throws {
        let identifier = Identifiers.Targets.Identifier(
            pbxProjEscapedName: "Subject",
            subIdentifier: .init(shard: "A_SHARD", hash: "A_HASH"),
            full: "A_ID /* Subject */",
            withoutComment: "A_ID"
        )
        let createBuildPhases = Generator.CreateBuildPhases(
            createBazelIntegrationBuildPhaseObject:
                Generator.CreateBazelIntegrationBuildPhaseObject(),
            createBuildFileSubIdentifier:
                Generator.CreateBuildFileSubIdentifier(),
            createCreateCompileDependenciesBuildPhaseObject:
                Generator.CreateCreateCompileDependenciesBuildPhaseObject(),
            createCreateLinkDependenciesBuildPhaseObject:
                Generator.CreateCreateLinkDependenciesBuildPhaseObject(),
            createEmbedAppExtensionsBuildPhaseObject:
                Generator.CreateEmbedAppExtensionsBuildPhaseObject(),
            createProductBuildFileObject:
                Generator.CreateProductBuildFileObject(),
            createSourcesBuildPhaseObject:
                Generator.CreateSourcesBuildPhaseObject()
        )

        let phases = createBuildPhases(
            consolidatedInputs: .init(srcs: [], nonArcSrcs: []),
            hasCParams: false,
            hasCxxParams: false,
            hasLinkParams: true,
            identifier: identifier,
            productType: .staticLibrary,
            shard: 0,
            usesInfoPlist: false,
            watchKitExtensionProductIdentifier: nil
        ).buildPhases

        XCTAssertTrue(
            phases.contains {
                $0.content.contains("name = \"Create Link Dependencies\";")
            }
        )

        let platformVariant = Target.PlatformVariant(
            xcodeConfigurations: ["Debug"],
            id: "ID config",
            bundleID: nil,
            compileTargetIDs: nil,
            packageBinDir: "bazel-out/package",
            outputsProductPath: nil,
            productName: "Subject",
            productBasename: "libSubject.a",
            moduleName: "Subject",
            platform: .iOSSimulator,
            osVersion: "17.0",
            arch: "arm64",
            executableName: nil,
            conditionalFiles: [],
            buildSettingsFromFile: [],
            linkParams: "bazel-out/package/Subject.preview.link.params",
            unitTestHost: nil,
            dSYMPathsBuildSetting: nil
        )
        let settings = try await Generator
            .CalculatePlatformVariantBuildSettings.defaultCallable(
                isBundle: false,
                originalProductBasename: "libSubject.a",
                productType: .staticLibrary,
                platformVariant: platformVariant
            )
        let settingsByKey = Dictionary(
            uniqueKeysWithValues: settings.map { ($0.key, $0.value) }
        )

        XCTAssertEqual(
            settingsByKey["OTHER_LIBTOOLFLAGS"],
            #""@$(DERIVED_FILE_DIR)/link.params""#
        )
        XCTAssertNil(settingsByKey["OTHER_LDFLAGS"])
    }
}
