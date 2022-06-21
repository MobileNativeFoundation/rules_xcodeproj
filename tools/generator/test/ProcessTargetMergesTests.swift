import CustomDump
import PathKit
import XCTest

@testable import generator

final class TargetMergingTests: XCTestCase {
    func test_no_merges() throws {
        // Arrange

        var targets = Fixtures.targets
        let targetMerges: [TargetID: Set<TargetID>] = [:]

        let expectedTargets = Fixtures.targets

        // Act

        try Generator.processTargetMerges(
            targets: &targets,
            targetMerges: targetMerges
        )

        // Assert

        XCTAssertNoDifference(targets, expectedTargets)
    }

    func test_merges_without_required_links() throws {
        // Arrange

        var targets = Fixtures.targets
        let targetMerges: [TargetID: Set<TargetID>] = [
            "A 1": ["A 2"],
            "B 1": ["B 2", "B 3"],
        ]

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
                // Inherited "A 1"'s `T`, `Y`, `Z`
                "T": .string("42"),
                "Y": .bool(true),
                "Z": .string("0")
            ],
            modulemaps: targets["A 1"]!.modulemaps,
            swiftmodules: targets["A 1"]!.swiftmodules,
            resourceBundleDependencies: targets["A 2"]!
                .resourceBundleDependencies,
            inputs: targets["A 2"]!.inputs.merging(targets["A 1"]!.inputs),
            linkerInputs: .init(
                staticFrameworks: targets["A 2"]!.linkerInputs.staticFrameworks,
                dynamicFrameworks: targets["A 2"]!
                    .linkerInputs.dynamicFrameworks,
                // Removed "A 1"'s product
                staticLibraries: [
                    .generated("a/c.a"),
                    .project("a/imported.a"),
                ]
            ),
            // Inherited "A 1"'s dependencies and removed "A 1"
            dependencies: ["C 1", "R 1"],
            outputs: targets["A 2"]!.outputs.merging(targets["A 1"]!.outputs)
        )
        expectedTargets["B 2"] = Target.mock(
            packageBinDir: targets["B 1"]!.packageBinDir,
            product: targets["B 2"]!.product,
            isSwift: targets["A 2"]!.isSwift,
            testHost: "A 2",
            modulemaps: targets["B 1"]!.modulemaps,
            swiftmodules: targets["B 1"]!.swiftmodules,
            resourceBundleDependencies: targets["B 2"]!
                .resourceBundleDependencies,
            inputs: targets["B 2"]!.inputs.merging(targets["B 1"]!.inputs),
            linkerInputs: .init(
                staticFrameworks: targets["B 2"]!.linkerInputs.staticFrameworks,
                dynamicFrameworks: targets["B 2"]!
                    .linkerInputs.dynamicFrameworks,
                // Removed "A 1"'s and "B 1"'s product
                staticLibraries: []
            ),
            // Inherited "B 1"'s dependencies and removed "A 1"
            dependencies: ["A 2"],
            outputs: targets["B 2"]!.outputs.merging(targets["B 1"]!.outputs)
        )
        expectedTargets["B 3"] = Target.mock(
            packageBinDir: targets["B 1"]!.packageBinDir,
            product: targets["B 3"]!.product,
            isSwift: targets["B 1"]!.isSwift,
            testHost: "A 2",
            modulemaps: targets["B 1"]!.modulemaps,
            swiftmodules: targets["B 1"]!.swiftmodules,
            resourceBundleDependencies: targets["B 3"]!
                .resourceBundleDependencies,
            inputs: targets["B 3"]!.inputs.merging(targets["B 1"]!.inputs),
            linkerInputs: .init(
                staticFrameworks: targets["B 3"]!.linkerInputs.staticFrameworks,
                dynamicFrameworks: targets["B 3"]!
                    .linkerInputs.dynamicFrameworks,
                // Removed "B 1"'s product
                staticLibraries: []
            ),
            // Inherited "B 1"'s "A 1" dependency and changed it to "A 2"
            dependencies: ["A 2"],
            outputs: targets["B 3"]!.outputs.merging(targets["B 1"]!.outputs)
        )

        // Act

        try Generator.processTargetMerges(
            targets: &targets,
            targetMerges: targetMerges
        )

        // Assert

        XCTAssertNoDifference(targets, expectedTargets)
    }
}
