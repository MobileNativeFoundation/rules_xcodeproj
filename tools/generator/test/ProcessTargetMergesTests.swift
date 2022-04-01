import CustomDump
import PathKit
import XCTest

@testable import generator

final class TargetMergingTests: XCTestCase {
    func test_no_merges() throws {
        // Arrange

        var targets = Fixtures.targets
        let potentialTargetMerges: [TargetID: Set<TargetID>] = [:]
        let requiredLinks = Set<Path>()

        let expectedTargets = Fixtures.targets
        let expectedInvalidMerges: [InvalidMerge] = []

        // Act

        let invalidMerges = try Generator.processTargetMerges(
            targets: &targets,
            potentialTargetMerges: potentialTargetMerges,
            requiredLinks: requiredLinks
        )

        // Assert

        XCTAssertNoDifference(targets, expectedTargets)
        XCTAssertNoDifference(invalidMerges, expectedInvalidMerges)
    }

    func test_merges_without_required_links() throws {
        // Arrange

        var targets = Fixtures.targets
        let potentialTargetMerges: [TargetID: Set<TargetID>] = [
            "A 1": ["A 2"],
            "B 1": ["B 2", "B 3"],
        ]
        let requiredLinks = Set<Path>()

        var expectedTargets = targets
        expectedTargets.removeValue(forKey: "A 1")
        expectedTargets.removeValue(forKey: "B 1")
        expectedTargets["A 2"] = Target.mock(
            packageBinDir: targets["A 1"]!.packageBinDir,
            product: targets["A 2"]!.product,
            isSwift: targets["A 1"]!.isSwift,
            buildSettings: [
                // Inherited "A 1"s `PRODUCT_MODULE_NAME`
                "PRODUCT_MODULE_NAME": .string("A"),
                // Keep "A 2"'s version of `T`
                "T": .string("43"),
                // Inherited "A 1"'s `Y`
                "Y": .bool(true),
                "Z": .string("0")
            ],
            frameworks: targets["A 2"]!.frameworks,
            modulemaps: targets["A 1"]!.modulemaps,
            swiftmodules: targets["A 1"]!.swiftmodules,
            resourceBundles: targets["A 2"]!.resourceBundles,
            inputs: targets["A 1"]!.inputs.union(targets["A 2"]!.inputs),
            // Removed "A 1"'s product
            links: ["a/c.a"],
            // Inherited "A 1"'s dependencies and removed "A 1"
            dependencies: ["C 1", "R 1"]
        )
        expectedTargets["B 2"] = Target.mock(
            packageBinDir: targets["B 1"]!.packageBinDir,
            product: targets["B 2"]!.product,
            isSwift: targets["A 2"]!.isSwift,
            testHost: "A 2",
            frameworks: targets["B 2"]!.frameworks,
            modulemaps: targets["B 1"]!.modulemaps,
            swiftmodules: targets["B 1"]!.swiftmodules,
            resourceBundles: targets["B 2"]!.resourceBundles,
            inputs: targets["B 1"]!.inputs.union(targets["B 2"]!.inputs),
            // Removed "A 1"'s and "B 1"'s product
            links: [],
            // Inherited "B 1"'s dependencies and removed "A 1"
            dependencies: ["A 2"]
        )
        expectedTargets["B 3"] = Target.mock(
            packageBinDir: targets["B 1"]!.packageBinDir,
            product: targets["B 3"]!.product,
            isSwift: targets["B 1"]!.isSwift,
            testHost: "A 2",
            frameworks: targets["B 3"]!.frameworks,
            modulemaps: targets["B 1"]!.modulemaps,
            swiftmodules: targets["B 1"]!.swiftmodules,
            resourceBundles: targets["B 3"]!.resourceBundles,
            inputs: targets["B 1"]!.inputs.union(targets["B 3"]!.inputs),
            // Removed "B 1"'s product
            links: [],
            // Inherited "B 1"'s "A 1" dependency and changed it to "A 2"
            dependencies: ["A 2"]
        )
        let expectedInvalidMerges: [InvalidMerge] = []

        // Act

        let invalidMerges = try Generator.processTargetMerges(
            targets: &targets,
            potentialTargetMerges: potentialTargetMerges,
            requiredLinks: requiredLinks
        )

        // Assert

        XCTAssertNoDifference(targets, expectedTargets)
        XCTAssertNoDifference(invalidMerges, expectedInvalidMerges)
    }

    func test_merges_with_required_links() throws {
        // Arrange

        var targets = Fixtures.targets
        // "B 2" having a link on "A 1" is a problem for Xcode, as both
        // "A 1" and a merged "A 2" would have to exist, and have the same
        // "PRODUCT_MODULE_NAME", which breaks indexing
        targets["B 2"] = Target.mock(
            packageBinDir: targets["B 2"]!.packageBinDir,
            product: targets["B 2"]!.product,
            isSwift: targets["B 2"]!.isSwift,
            frameworks: targets["B 2"]!.frameworks,
            modulemaps: targets["B 2"]!.modulemaps,
            swiftmodules: targets["B 2"]!.swiftmodules,
            resourceBundles: targets["B 2"]!.resourceBundles,
            inputs: targets["B 2"]!.inputs,
            links: ["z/A.a", "a/b.framework"],
            dependencies: targets["B 2"]!.dependencies
        )
        let potentialTargetMerges: [TargetID: Set<TargetID>] = [
            "A 1": ["A 2"],
            "B 1": ["B 2", "B 3"],
        ]
        let requiredLinks: Set<Path> = ["z/A.a"]

        var expectedTargets = targets
        expectedTargets.removeValue(forKey: "B 1")
        expectedTargets["B 2"] = Target.mock(
            packageBinDir: targets["B 1"]!.packageBinDir,
            product: targets["B 2"]!.product,
            isSwift: targets["B 1"]!.isSwift,
            frameworks: targets["B 2"]!.frameworks,
            modulemaps: targets["B 1"]!.modulemaps,
            swiftmodules: targets["B 1"]!.swiftmodules,
            resourceBundles: targets["B 2"]!.resourceBundles,
            inputs: targets["B 1"]!.inputs.union(targets["B 2"]!.inputs),
            // Removed "B 1"'s product
            links: ["z/A.a"],
            // Inherited "B 1"'s dependencies
            dependencies: ["A 1", "A 2"]
        )
        expectedTargets["B 3"] = Target.mock(
            packageBinDir: targets["B 1"]!.packageBinDir,
            product: targets["B 3"]!.product,
            isSwift: targets["B 1"]!.isSwift,
            testHost: "A 2",
            frameworks: targets["B 3"]!.frameworks,
            modulemaps: targets["B 1"]!.modulemaps,
            swiftmodules: targets["B 1"]!.swiftmodules,
            resourceBundles: targets["B 3"]!.resourceBundles,
            inputs: targets["B 1"]!.inputs.union(targets["B 3"]!.inputs),
            // Removed "B 1"'s product
            links: [],
            // Inherited "B 1"'s dependencies
            dependencies: ["A 1", "A 2"]
        )
        let expectedInvalidMerges = [
            InvalidMerge(source: "A 1", destinations: ["A 2"]),
        ]

        // Act

        let invalidMerges = try Generator.processTargetMerges(
            targets: &targets,
            potentialTargetMerges: potentialTargetMerges,
            requiredLinks: requiredLinks
        )

        // Assert

        XCTAssertNoDifference(targets, expectedTargets)
        XCTAssertNoDifference(invalidMerges, expectedInvalidMerges)
    }
}
