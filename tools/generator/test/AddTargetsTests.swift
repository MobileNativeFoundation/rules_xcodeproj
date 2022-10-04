import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class AddTargetsTests: XCTestCase {
    func test_integration() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let generatorLabel = "//:project"
        let generatorConfiguration = "1234zyx"
        let consolidatedTargets = Fixtures.consolidatedTargets
        let workspaceDirectory: Path = "/app-project"
        let externalDirectory: Path = "/some/bazel11/external"
        let bazelOutDirectory: Path = "/some/bazel11/bazel-out"
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let filePathResolver = FilePathResolver(
            workspaceDirectory: workspaceDirectory,
            externalDirectory: externalDirectory,
            bazelOutDirectory: bazelOutDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let (files, _, _, _, _) = Fixtures.files(
            in: pbxProj,
            buildMode: .xcode,
            parentGroup: mainGroup
        )
        let (expectedFiles, _, _, _, _) = Fixtures.files(
            in: expectedPBXProj,
            buildMode: .xcode,
            parentGroup: expectedMainGroup
        )

        let products = Fixtures.products(in: pbxProj, parentGroup: mainGroup)
        let expectedProducts = Fixtures.products(
            in: expectedPBXProj,
            parentGroup: expectedMainGroup
        )

        let bazelDependenciesTarget = Fixtures.bazelDependenciesTarget(
            in: pbxProj,
            generatorLabel: generatorLabel,
            generatorConfiguration: generatorConfiguration
        )
        let expectedBazelDependenciesTarget = Fixtures.bazelDependenciesTarget(
            in: expectedPBXProj,
            generatorLabel: generatorLabel,
            generatorConfiguration: generatorConfiguration
        )

        let disambiguatedTargets = Fixtures.disambiguatedTargets(
            consolidatedTargets
        )
        let expectedTargets = Fixtures.pbxTargets(
            in: expectedPBXProj,
            disambiguatedTargets: disambiguatedTargets,
            files: expectedFiles,
            products: expectedProducts,
            bazelDependenciesTarget: expectedBazelDependenciesTarget
        )

        // Act

        let createdTargets = try Generator.addTargets(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            products: products,
            files: files,
            filePathResolver: filePathResolver,
            bazelDependenciesTarget: bazelDependenciesTarget
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(
            createdTargets.map(KeyAndValue.init).sorted(),
            expectedTargets.map(KeyAndValue.init).sorted()
        )

        // We only need the rest of the asserts if the targets are equivalent
        guard createdTargets == expectedTargets else { return }

        for (key, target) in expectedTargets {
            guard let createdTarget = createdTargets[key] else { continue }
            // The assert above won't tell us when the build phases are
            // different, and the assert below won't give us the context of
            // which target, so we assert here as well.
            XCTAssertNoDifference(
                createdTarget.buildPhases,
                target.buildPhases,
                "\(key)"
            )
        }

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
