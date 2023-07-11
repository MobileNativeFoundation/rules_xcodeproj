import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

struct ConsolidationMapsArguments: ParsableArguments {
    @Option(
        name: .customLong("consolidation-map-output-paths"),
        parsing: .upToNextOption,
        help: """
Paths to where the target consolidation map files should be written.
""",
        transform: { URL(fileURLWithPath: $0, isDirectory: false) }
    )
    var outputPaths: [URL]

    @Option(
        parsing: .upToNextOption,
        help: """
Number of labels per consolidation map. For example, '--label-counts 2 3' \
means the first consolidation map (as specified by \
<consolidation-map-output-paths>) should include the first two labels from \
<labels>, and the second consolidation map should include the next three \
labels. There must be exactly as many label counts as there are consolidation \
maps. The sum of all of the label counts must equal the number of labels.
"""
    )
    var labelCounts: [Int]

    @Option(
        parsing: .upToNextOption,
        help: """
Labels for all of the targets among all of the consolidation maps. See \
<label-counts> for how these labels will be distributed between the \
consolidation maps.

All targets with the same target name (e.g. //some/package:target_name and \
//another/package:target_name) must be associated with the same consolidation \
map. This is a requirement for the `pbxnativetargets` generator to work.
"""
    )
    var labels: [BazelLabel]

    @Option(
        parsing: .upToNextOption,
        help: """
Number of targets per label. For example, '--target-counts 2 3' means the \
first label (as specified by <labels>) should include the first two targets \
from <targets>, and the second label should include the next three targets. \
There must be exactly as many target counts as there are labels. The sum of \
all of the target counts must equal the number of targets.
"""
    )
    var targetCounts: [Int]

    @Option(
        parsing: .upToNextOption,
        help: """
Target IDs for all of the targets among all of the labels. See <target-counts> \
for how these targets will be distributed between the labels.
"""
    )
    var targets: [TargetID]

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Xcode configurations per target. For example, \
'--xcode-configuration-counts 2 3' means the first target (as specified by \
<targets>) should include the first names from <xcode-configurations>, and the \
second target should include the next three names. There must be exactly as \
many Xcode configuration counts as there are targets. The sum of all of the \
Xcode configuration counts must equal the number of <xcode-configurations> \
elements.
"""
    )
    var xcodeConfigurationCounts: [Int]

    @Option(
        parsing: .upToNextOption,
        help: """
Xcode configuration names for all of the targets. See \
<xcode-configuration-counts> for how these names will be distributed between \
the targets.
"""
    )
    var xcodeConfigurations: [String]

    @Option(
        parsing: .upToNextOption,
        help: """
Product type identifiers for all of the targets. There must be exactly as many \
product types as there are targets.
"""
    )
    var productTypes: [PBXProductType]

    @Option(
        parsing: .upToNextOption,
        help: """
Paths to the product for all of the targets. There must be exactly as many \
paths as there are targets.
"""
    )
    var productPaths: [String]

    @Option(
        parsing: .upToNextOption,
        help: """
Names of the platform for all of the targets. There must be exactly as many \
platform names as there are targets.
"""
    )
    var platforms: [Platform]

    @Option(
        parsing: .upToNextOption,
        help: """
Minimum OS versions for all of the targets. There must be exactly as many \
versions as there are targets.
"""
    )
    var osVersions: [SemanticVersion]

    @Option(
        parsing: .upToNextOption,
        help: """
CPU architectures for all of the targets. There must be exactly as many \
architectures as there are targets.
"""
    )
    var archs: [String]

    @Option(
        parsing: .upToNextOption,
        help: """
Number of dependencies per target. For example, '--dependency-counts 2 3' \
means the first target (as specified by <targets>) should include the first \
two dependencies from <dependencies>, and the second target should include the \
next three dependencies. There must be exactly as many dependency counts as \
there are targets. The sum of all of the dependency counts must equal the \
number of <dependencies> elements.
"""
    )
    var dependencyCounts: [Int]

    @Option(
        parsing: .upToNextOption,
        help: """
Dependencies for all of the targets. See <dependency-counts> for how these \
dependencies will be distributed between the targets.
"""
    )
    var dependencies: [TargetID]

    mutating func validate() throws {
        guard labelCounts.count == outputPaths.count else {
            throw ValidationError("""
<label-counts> (\(labelCounts.count) elements) must have exactly as many \
elements as <consolidation-map-output-paths> (\(outputPaths.count) elements).
""")
        }

        let labelCountsSum = labelCounts.reduce(0, +)
        guard labelCountsSum == labels.count else {
            throw ValidationError("""
The sum of <label-counts> (\(labelCountsSum)) must equal the number of \
<labels> elements (\(labels.count)).
""")
        }

        guard targetCounts.count == labels.count else {
            throw ValidationError("""
<target-counts> (\(targetCounts.count) elements) must have exactly as many \
elements as <labels> (\(labels.count) elements).
""")
        }

        let targetCountsSum = targetCounts.reduce(0, +)
        guard targetCountsSum == targets.count else {
            throw ValidationError("""
The sum of <target-counts> (\(targetCountsSum)) must equal the number of \
<targets> elements (\(targets.count)).
""")
        }

        guard xcodeConfigurationCounts.count == targets.count else {
            throw ValidationError("""
<xcode-configuration-counts> (\(xcodeConfigurationCounts.count) elements) must \
have exactly as many elements as <targets> (\(targets.count) elements).
""")
        }

        let xcodeConfigurationCountsSum = xcodeConfigurationCounts.reduce(0, +)
        guard xcodeConfigurationCountsSum == xcodeConfigurations.count else {
            throw ValidationError("""
The sum of <xcode-configuration-counts> (\(xcodeConfigurationCountsSum)) must \
equal the number of <xcode-configurations> elements \
(\(xcodeConfigurations.count)).
""")
        }

        guard productTypes.count == targets.count else {
            throw ValidationError("""
<product-types> (\(productTypes.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        guard productPaths.count == targets.count else {
            throw ValidationError("""
<product-paths> (\(productPaths.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        guard platforms.count == targets.count else {
            throw ValidationError("""
<platforms> (\(platforms.count) elements) must have exactly as many elements \
as <targets> (\(targets.count) elements).
""")
        }

        guard osVersions.count == targets.count else {
            throw ValidationError("""
<os-versions> (\(osVersions.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        guard archs.count == targets.count else {
            throw ValidationError("""
<archs> (\(archs.count) elements) must have exactly as many elements as \
<targets> (\(targets.count) elements).
""")
        }

        guard dependencyCounts.count == targets.count else {
            throw ValidationError("""
<dependency-counts> (\(dependencyCounts.count) elements) must have exactly as \
many elements as <targets> (\(targets.count) elements).
""")
        }

        let dependencyCountsSum = dependencyCounts.reduce(0, +)
        guard dependencyCountsSum == dependencies.count else {
            throw ValidationError("""
The sum of <dependency-counts> (\(dependencyCountsSum)) must equal the number \
of <dependencies> elements (\(dependencies.count)).
""")
        }
    }
}

// MARK: - ConsolidationMapArguments

struct ConsolidationMapArguments: Equatable {
    let outputPath: URL
    let targets: [Target]
}

extension ConsolidationMapsArguments {
    func toConsolidationMapArguments() -> [ConsolidationMapArguments] {
        var dependenciesStartIndex = dependencies.startIndex
        var labelsStartIndex = labels.startIndex
        var targetsStartIndex = targets.startIndex
        var xcodeConfigurationsStartIndex = xcodeConfigurations.startIndex
        var consolidationMapArguments: [ConsolidationMapArguments] = []
        for (outputPath, labelCount) in zip(outputPaths, labelCounts) {
            // Collect labels and targetCounts for this consolidationMap
            let labelsEndIndex = labelsStartIndex.advanced(by: labelCount)
            let labelsRange = labelsStartIndex ..< labelsEndIndex
            labelsStartIndex = labelsEndIndex
            let labels = self.labels[labelsRange]
            let targetCounts = self.targetCounts[labelsRange]

            var targetArguments: [Target] = []
            for (label, targetCount) in zip(labels, targetCounts) {
                // Collect targets and dependencyCounts for this label
                let targetsEndIndex =
                    targetsStartIndex.advanced(by: targetCount)
                let targetsRange = targetsStartIndex ..< targetsEndIndex
                targetsStartIndex = targetsEndIndex
                let targets = self.targets[targetsRange]
                let dependencyCounts = self.dependencyCounts[targetsRange]

                for targetIndex in targets.indices {
                    // Collect Xcode configurations and dependencies for this
                    // target
                    let dependencies = dependencies.slicedBy(
                        targetIndex: targetIndex,
                        counts: dependencyCounts,
                        startIndex: &dependenciesStartIndex
                    )
                    let xcodeConfigurations = xcodeConfigurations.slicedBy(
                        targetIndex: targetIndex,
                        counts: xcodeConfigurationCounts,
                        startIndex: &xcodeConfigurationsStartIndex
                    )

                    targetArguments.append(
                        .init(
                            id: targets[targetIndex],
                            label: label,
                            xcodeConfigurations: xcodeConfigurations,
                            productType: productTypes[targetIndex],
                            productPath: productPaths[targetIndex],
                            platform: platforms[targetIndex],
                            osVersion: osVersions[targetIndex],
                            arch: archs[targetIndex],
                            dependencies: dependencies
                        )
                    )
                }
            }

            consolidationMapArguments.append(
                .init(
                    outputPath: outputPath,
                    targets: targetArguments
                )
            )
        }

        return consolidationMapArguments
    }
}

private extension Array {
    func slicedBy<CountsCollection>(
        targetIndex: Array<TargetID>.Index,
        counts: CountsCollection,
        startIndex: inout Index
    ) -> Self where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return self
        }

        let endIndex = startIndex.advanced(by: counts[targetIndex])
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return Array(self[range])
    }
}
