import PathKit
import XcodeProj
import XCTest

@testable import generator

class CreateXCSchemesTests: XCTestCase {
    let workspaceOutputPath = Path("examples/foo/Foo.xcodeproj")
    lazy var referencedContainer = XcodeProjContainerReference(
        xcodeprojPath: workspaceOutputPath
    )

    // TODO(chuck): Fix wrap when done.
    let pbxTargetsDict: [TargetID: PBXNativeTarget] = Fixtures.pbxTargetsWithDependencies(
        in: Fixtures.pbxProj(),
        targets: Fixtures.targets
    )

    func assertScheme(
        schemesDict: [String: XCScheme],
        targetName: String,
        shouldExpectBuildActionEntries: Bool,
        shouldExpectTestables: Bool,
        shouldExpectBuildableProductRunnable: Bool
    ) {
        let targetID = TargetID(targetName)
        guard let target = pbxTargetsDict[targetID] else {
            XCTFail("Did not find the target '\(targetName)'")
            return
        }
        guard let scheme = schemesDict[target.schemeName] else {
            XCTFail("Did not find a scheme named \(target.schemeName)")
            return
        }

        // Expected values

        let expectedBuildConfigurationName = target.defaultBuildConfigurationName
        let expectedBuildableReference = target.createBuildableReference(
            referencedContainer: referencedContainer
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

        guard let buildAction = scheme.buildAction else {
            XCTFail("Expected a build action for \(scheme.name)")
            return
        }
        XCTAssertEqual(
            buildAction.buildActionEntries,
            expectedBuildActionEntries,
            "buildActionEntries did not match for \(scheme.name)"
        )
        XCTAssertTrue(
            buildAction.parallelizeBuild,
            "parallelizeBuild was not true for \(scheme.name)"
        )
        XCTAssertTrue(
            buildAction.buildImplicitDependencies,
            "buildImplicitDependencies was not true for \(scheme.name)"
        )

        guard let testAction = scheme.testAction else {
            XCTFail("Expected a test action for \(scheme.name)")
            return
        }
        XCTAssertNil(
            testAction.macroExpansion,
            "macroExpansion was not nil for \(scheme.name)"
        )
        XCTAssertEqual(
            testAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the test action buildConfiguration did not match for \(scheme.name)"
        )
        XCTAssertEqual(
            testAction.testables,
            expectedTestables,
            "testables did not match for \(scheme.name)"
        )

        guard let launchAction = scheme.launchAction else {
            XCTFail("Expected a launch action for \(scheme.name)")
            return
        }
        XCTAssertEqual(
            launchAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the launch action buildConfiguration did not match for \(scheme.name)"
        )
        XCTAssertEqual(
            launchAction.runnable,
            expectedBuildableProductRunnable,
            "runnable did not match for \(scheme.name)"
        )

        guard let analyzeAction = scheme.analyzeAction else {
            XCTFail("Expected an analyze action for \(scheme.name)")
            return
        }
        XCTAssertEqual(
            analyzeAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the analyze action buildConfiguration did not match for \(scheme.name)"
        )

        guard let archiveAction = scheme.archiveAction else {
            XCTFail("Expected an archive action for \(scheme.name)")
            return
        }
        XCTAssertEqual(
            archiveAction.buildConfiguration,
            expectedBuildConfigurationName,
            "the archive action buildConfiguration did not match for \(scheme.name)"
        )
        XCTAssertTrue(
            archiveAction.revealArchiveInOrganizer,
            "revealArchiveInOrganizer did not match for \(scheme.name)"
        )
    }

    func test_createXCSchemes_WithNoTargets() throws {
        let schemes = try Generator.createXCSchemes(
            workspaceOutputPath: workspaceOutputPath,
            pbxTargets: [:]
        )
        let expected = [XCScheme]()
        XCTAssertEqual(schemes, expected)
    }

    func test_createXCSchemes_WithTargets() throws {
        let schemes = try Generator.createXCSchemes(
            workspaceOutputPath: workspaceOutputPath,
            pbxTargets: pbxTargetsDict
        )
        XCTAssertEqual(schemes.count, pbxTargetsDict.count)

        let schemesDict = Dictionary(uniqueKeysWithValues: schemes.map { ($0.name, $0) })

        // // DEBUG BEGIN
        // fputs("*** CHUCK pbxTargetsDict:\n", stderr)
        // for (key, item) in pbxTargetsDict {
        //     fputs("*** CHUCK   \(key) : \(String(reflecting: item.name))\n", stderr)
        //     fputs("*** CHUCK      item.productName: \(String(reflecting: item.productName))\n", stderr)
        //     fputs("*** CHUCK      item.schemeName: \(String(reflecting: item.schemeName))\n", stderr)
        //     fputs("*** CHUCK      item.isTestable: \(String(reflecting: item.isTestable))\n", stderr)
        //     fputs("*** CHUCK      item.isLaunchable: \(String(reflecting: item.isLaunchable))\n", stderr)
        // }
        // // DEBUG END

        // Library
        assertScheme(
            schemesDict: schemesDict,
            targetName: "A 1",
            shouldExpectBuildActionEntries: true,
            shouldExpectTestables: false,
            shouldExpectBuildableProductRunnable: false
        )

        // Testable and launchable
        assertScheme(
            schemesDict: schemesDict,
            targetName: "B 2",
            shouldExpectBuildActionEntries: false,
            shouldExpectTestables: true,
            shouldExpectBuildableProductRunnable: true
        )

        // Launchable, not testable
        assertScheme(
            schemesDict: schemesDict,
            targetName: "A 2",
            shouldExpectBuildActionEntries: true,
            shouldExpectTestables: false,
            shouldExpectBuildableProductRunnable: true
        )
    }
}
