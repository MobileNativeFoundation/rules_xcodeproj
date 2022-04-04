import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class AddTargetsTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let mainGroup = pbxProj.rootObject!.mainGroup!
        let expectedPBXProj = Fixtures.pbxProj()
        let expectedMainGroup = expectedPBXProj.rootObject!.mainGroup!

        let xcodeprojBazelLabel = "//:project"
        let targets = Fixtures.targets
        let externalDirectory: Path = "/ext"
        let generatedDirectory: Path = "/bazel-leave"
        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let filePathResolver = FilePathResolver(
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let (files, _) = Fixtures.files(in: pbxProj, parentGroup: mainGroup)
        let (expectedFiles, _) = Fixtures.files(
            in: expectedPBXProj,
            parentGroup: expectedMainGroup
        )

        let products = Fixtures.products(in: pbxProj, parentGroup: mainGroup)
        let expectedProducts = Fixtures.products(
            in: expectedPBXProj,
            parentGroup: expectedMainGroup
        )

        let disambiguatedTargets = Fixtures.disambiguatedTargets(targets)

        let expectedTargets = Fixtures.pbxTargets(
            in: expectedPBXProj,
            disambiguatedTargets: disambiguatedTargets,
            files: expectedFiles,
            products: expectedProducts,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel
        )

        // Act

        let createdTargets = try Generator.addTargets(
            in: pbxProj,
            for: disambiguatedTargets,
            products: products,
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdTargets, expectedTargets)

        // We only need the rest of the asserts if the targets are equivalent
        guard createdTargets == expectedTargets else { return }

        for (id, target) in expectedTargets {
            guard let createdTarget = createdTargets[id] else { continue }
            // The assert above won't tell us when the build phases are
            // different, and the assert below won't give us the context of
            // which target, so we assert here as well.
            XCTAssertNoDifference(
                createdTarget.buildPhases,
                target.buildPhases,
                id.rawValue
            )
        }

        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
