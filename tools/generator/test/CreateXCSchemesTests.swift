import PathKit
import XcodeProj
import XCTest

@testable import generator

class CreateXCSchemesTests: XCTestCase {
    let filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )
    let pbxTargetsDict: [TargetID: PBXTarget] =
        Fixtures.pbxTargets(in: Fixtures.pbxProj(), targets: Fixtures.targets).0

    func assertScheme(
        schemesDict: [String: XCScheme],
        targetID: TargetID,
        shouldExpectBuildActionEntries: Bool,
        shouldExpectTestables: Bool,
        shouldExpectBuildableProductRunnable: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        guard let target = pbxTargetsDict[targetID] else {
            XCTFail(
                "Did not find the target '\(targetID)'",
                file: file,
                line: line
            )
            return
        }
        let schemeName = target.schemeName
        guard let scheme = schemesDict[schemeName] else {
            XCTFail(
                "Did not find a scheme named \(schemeName)",
                file: file,
                line: line
            )
            return
        }

        // Expected values

        let expectedBuildConfigurationName = target.defaultBuildConfigurationName
        let expectedBuildableReference = try target.createBuildableReference(
            referencedContainer: filePathResolver.containerReference
        )
        let expectedBuildActionEntries: [XCScheme.BuildAction.Entry] =
            shouldExpectBuildActionEntries ?
            [.init(
                buildableReference: expectedBuildableReference,
                buildFor: [.running, .testing, .profiling, .archiving, .analyzing]
            )] : []
        let expectedTestables: [XCScheme.TestableReference] =
            shouldExpectTestables ?
            [.init(
                skipped: false,
                buildableReference: expectedBuildableReference
            )] : []
        let expectedBuildableProductRunnable: XCScheme.BuildableProductRunnable? =
            shouldExpectBuildableProductRunnable ?
            XCScheme.BuildableProductRunnable(
                buildableReference: expectedBuildableReference
            ) : nil

        // Assertions

        XCTAssertNotNil(
            scheme.lastUpgradeVersion,
            file: file,
            line: line
        )
        XCTAssertNotNil(
            scheme.version,
            file: file,
            line: line
        )

        guard let buildAction = scheme.buildAction else {
            XCTFail(
                "Expected a build action for \(scheme.name)",
                file: file,
                line: line
            )
            return
        }
        XCTAssertEqual(
            buildAction.buildActionEntries,
            expectedBuildActionEntries,
            "buildActionEntries did not match for \(scheme.name)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            buildAction.parallelizeBuild,
            "parallelizeBuild was not true for \(scheme.name)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            buildAction.buildImplicitDependencies,
            "buildImplicitDependencies was not true for \(scheme.name)",
            file: file,
            line: line
        )

        guard let testAction = scheme.testAction else {
            XCTFail(
                "Expected a test action for \(scheme.name)",
                file: file,
                line: line
            )
            return
        }
        XCTAssertNil(
            testAction.macroExpansion,
            "macroExpansion was not nil for \(scheme.name)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            testAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the test action buildConfiguration did not match for \(scheme.name)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            testAction.testables,
            expectedTestables,
            "testables did not match for \(scheme.name)",
            file: file,
            line: line
        )

        guard let launchAction = scheme.launchAction else {
            XCTFail(
                "Expected a launch action for \(scheme.name)",
                file: file,
                line: line
            )
            return
        }
        XCTAssertEqual(
            launchAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the launch action buildConfiguration did not match for \(scheme.name)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            launchAction.runnable,
            expectedBuildableProductRunnable,
            "runnable did not match for \(scheme.name)",
            file: file,
            line: line
        )

        guard let analyzeAction = scheme.analyzeAction else {
            XCTFail(
                "Expected an analyze action for \(scheme.name)",
                file: file,
                line: line
            )
            return
        }
        XCTAssertEqual(
            analyzeAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the analyze action buildConfiguration did not match for \(scheme.name)",
            file: file,
            line: line
        )

        guard let archiveAction = scheme.archiveAction else {
            XCTFail(
                "Expected an archive action for \(scheme.name)",
                file: file,
                line: line
            )
            return
        }
        XCTAssertEqual(
            archiveAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the archive action buildConfiguration did not match for \(scheme.name)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            archiveAction.revealArchiveInOrganizer,
            "revealArchiveInOrganizer did not match for \(scheme.name)",
            file: file,
            line: line
        )
    }

    func test_createXCSchemes_withNoTargets() throws {
        let schemes = try Generator.createXCSchemes(
            filePathResolver: filePathResolver,
            pbxTargets: [:]
        )
        let expected = [XCScheme]()
        XCTAssertEqual(schemes, expected)
    }

    func test_createXCSchemes_withTargets() throws {
        let schemes = try Generator.createXCSchemes(
            filePathResolver: filePathResolver,
            pbxTargets: pbxTargetsDict
        )
        XCTAssertEqual(schemes.count, pbxTargetsDict.count)

        let schemesDict = Dictionary(uniqueKeysWithValues: schemes.map { ($0.name, $0) })

        // Library
        try assertScheme(
            schemesDict: schemesDict,
            targetID: "A 1",
            shouldExpectBuildActionEntries: true,
            shouldExpectTestables: false,
            shouldExpectBuildableProductRunnable: false
        )

        // Testable and launchable
        try assertScheme(
            schemesDict: schemesDict,
            targetID: "B 2",
            shouldExpectBuildActionEntries: false,
            shouldExpectTestables: true,
            shouldExpectBuildableProductRunnable: true
        )

        // Launchable, not testable
        try assertScheme(
            schemesDict: schemesDict,
            targetID: "A 2",
            shouldExpectBuildActionEntries: true,
            shouldExpectTestables: false,
            shouldExpectBuildableProductRunnable: true
        )
    }
}
