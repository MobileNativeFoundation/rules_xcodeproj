import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

struct TargetsArguments: ParsableArguments {
    @Option(
        parsing: .upToNextOption,
        help: "Target IDs for all of the targets."
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
Package bin dir for all of the targets. There must be exactly as many values \
as there are targets.
"""
    )
    var packageBinDirs: [String]

    @Option(
        parsing: .upToNextOption,
        help: """
PRODUCT_NAME for all of the targets. There must be exactly as many values as \
there are targets.
"""
    )
    var productNames: [String]

    @Option(
        parsing: .upToNextOption,
        help: """
Basename of the (potentially modified) product path for all of the targets. \
This is possibly different from 'basename(productPath)', because it might \
reference a post-processed product (e.g. "tool_codesigned" instead of "tool").
"""
    )
    var productBasenames: [String]

    @Option(
        parsing: .upToNextOption,
        help: """
Module names for all of the targets. There must be exactly as many module \
names as there are targets. If a target doesn't have a module name, use an \
empty string.
"""
    )
    var moduleNames: [String]

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
Paths to files containing the compiler build settings for all of the targets. \
If there is no file, then an empty string should be used. There must be \
exactly as paths as there are targets.
""",
        transform: { path in
            guard !path.isEmpty else {
                return nil
            }
            return URL(fileURLWithPath: path, isDirectory: false)
        }
    )
    var buildSettingsFiles: [URL?]

    @Option(
        parsing: .upToNextOption,
        help: """
If the target has C params (as "0" or "1"), for all of the targets. There must \
be exactly as many bools as there are targets.
""",
        transform: { $0 == "1" }
    )
    var hasCParams: [Bool]

    @Option(
        parsing: .upToNextOption,
        help: """
If the target has C++ params (as "0" or "1"), for all of the targets. There \
must be exactly as many bools as there are targets.
""",
        transform: { $0 == "1" }
    )
    var hasCxxParams: [Bool]

    @Option(
        parsing: .upToNextOption,
        help: """
Number of srcs per target. For example, '--srcs-counts 2 3' means the first
target (as specified by <targets>) should include the first two srcs from \
<srcs>, and the second target should include the next three srcs. There must \
be exactly as many srcs counts as there are targets, or no srcs counts if \
there are no srcs among all of the targets. The sum of all of the srcs counts \
must equal the number of <srcs> elements.
"""
    )
    var srcsCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Paths to src files for all of the targets. See <srcs-counts> for how these \
srcs will be distributed between the targets.
"""
    )
    var srcs: [BazelPath] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of non-arc srcs per target. For example, '--non-arc-srcs-counts 2 3' \
means the first target (as specified by <targets>) should include the first \
two srcs from <non-arc-srcs>, and the second target should include the next \
three srcs. There must be exactly as many non-arc srcs counts as there are \
targets, or no non-arc srcs counts if there are no non-arc srcs among all of \
the targets. The sum of all of the non-arc srcs counts must equal the number \
of <non-arc-srcs> elements.
"""
    )
    var nonArcSrcsCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Paths to non-arc src files for all of the targets. See <non-arc-srcs-counts> \
for how these srcs will be distributed between the targets.
"""
    )
    var nonArcSrcs: [BazelPath] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of hdrs per target. For example, '--hdrs-counts 2 3' means the first
target (as specified by <targets>) should include the first two hdrs from \
<hdrs>, and the second target should include the next three hdrs. There must \
be exactly as many hdrs counts as there are targets, or no hdrs counts if \
there are no hdrs among all of the targets. The sum of all of the hdrs counts \
must equal the number of <hdrs> elements.
"""
    )
    var hdrsCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Paths to hdr files for all of the targets. See <hdrs-counts> for how these \
hdrs will be distributed between the targets.
"""
    )
    var hdrs: [BazelPath] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of resources per target. For example, '--resources-counts 2 3' means \
the first target (as specified by <targets>) should include the first two \
resources from <resources>, and the second target should include the next \
three resources. There must be exactly as many resources counts as there are \
targets, or no resources counts if there are no resources among all of the \
targets. The sum of all of the resources counts must equal the number of \
<resources> elements.
"""
    )
    var resourcesCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Paths to resource files for all of the targets. See <resources-counts> for how \
these resources will be distributed between the targets.
"""
    )
    var resources: [BazelPath] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of folder resources per target. For example, '--folder-resources-counts \
2 3' means the first target (as specified by <targets>) should include the \
first two folder resources from <folder-resources>, and the second target \
should include the next three folder resources. There must be exactly as many \
folder resources counts as there are targets, or no folder resources counts if \
there are no folder resources among all of the targets. The sum of all of the \
folder resources counts must equal the number of <folder-resources> elements.
"""
    )
    var folderResourcesCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Paths to folder resource directories for all of the targets. See \
<folder-resources-counts> for how these folder resources will be distributed \
between the targets.
""",
        transform: { BazelPath($0, isFolder: true) }
    )
    var folderResources: [BazelPath] = []

    @Option(
        parsing: .upToNextOption,
        help: """
dSYM paths build setting string for all of the targets. If there isn't a \
build setting string for a target (e.g. non-top level targets), then an empty \
string should be used. There must be exactly as many build setting strings as \
there are targets.
"""
    )
    var dsymPaths: [String]

    mutating func validate() throws {
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

        guard packageBinDirs.count == targets.count else {
            throw ValidationError("""
<package-bin-dirs> (\(packageBinDirs.count) elements) must have exactly as \
many elements as <targets> (\(targets.count) elements).
""")
        }

        guard productNames.count == targets.count else {
            throw ValidationError("""
<product-names> (\(productNames.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        guard moduleNames.count == targets.count else {
            throw ValidationError("""
<module-names> (\(moduleNames.count) elements) must have exactly as many \
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

        guard buildSettingsFiles.count == targets.count else {
            throw ValidationError("""
<compiler-build-setting-files> (\(buildSettingsFiles.count) elements) \
must have exactly as many elements as <targets> (\(targets.count) elements).
""")
        }

        guard hasCParams.count == targets.count else {
            throw ValidationError("""
<has-c-params> (\(hasCParams.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        guard hasCxxParams.count == targets.count else {
            throw ValidationError("""
<has-c-params> (\(hasCxxParams.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        let srcsCountsSum = srcsCounts.reduce(0, +)
        guard srcsCountsSum == srcs.count else {
            throw ValidationError("""
The sum of <srcs-counts> (\(srcsCountsSum)) must equal the number of <srcs> \
elements (\(srcs.count)).
""")
        }

        guard srcsCountsSum == 0 || srcsCounts.count == targets.count else {
            throw ValidationError("""
<srcs-counts> (\(srcsCounts.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        let nonArcSrcsCountsSum = nonArcSrcsCounts.reduce(0, +)
        guard nonArcSrcsCountsSum == nonArcSrcs.count else {
            throw ValidationError("""
The sum of <non-arc-srcs-counts> (\(nonArcSrcsCountsSum)) must equal the \
number of <non-arc-srcs> elements (\(nonArcSrcs.count)).
""")
        }

        guard nonArcSrcsCountsSum == 0 ||
            nonArcSrcsCounts.count == targets.count
        else {
            throw ValidationError("""
<non-arc-srcs-counts> (\(nonArcSrcsCounts.count) elements) must have exactly \
as many elements as <targets> (\(targets.count) elements).
""")
        }

        let hdrsCountsSum = hdrsCounts.reduce(0, +)
        guard hdrsCountsSum == hdrs.count else {
            throw ValidationError("""
The sum of <hdrs-counts> (\(hdrsCountsSum)) must equal the number of <hdrs> \
elements (\(hdrs.count)).
""")
        }

        guard hdrsCountsSum == 0 || hdrsCounts.count == targets.count else {
            throw ValidationError("""
<hdrs-counts> (\(hdrsCounts.count) elements) must have exactly as many \
elements as <targets> (\(targets.count) elements).
""")
        }

        let resourcesCountsSum = resourcesCounts.reduce(0, +)
        guard resourcesCountsSum == resources.count else {
            throw ValidationError("""
The sum of <resources-counts> (\(resourcesCountsSum)) must equal the number of \
<resources> elements (\(resources.count)).
""")
        }

        guard resourcesCountsSum == 0 || resourcesCounts.count == targets.count
        else {
            throw ValidationError("""
<resources-counts> (\(resourcesCounts.count) elements) must have exactly as \
many elements as <targets> (\(targets.count) elements).
""")
        }

        let folderResourcesCountsSum = folderResourcesCounts.reduce(0, +)
        guard folderResourcesCountsSum == folderResources.count else {
            throw ValidationError("""
The sum of <folder-resources-counts> (\(folderResourcesCountsSum)) must equal \
the number of <folder-resources> elements (\(folderResources.count)).
""")
        }

        guard folderResourcesCountsSum == 0 ||
            folderResourcesCounts.count == targets.count
        else {
            throw ValidationError("""
<folder-resources-counts> (\(folderResourcesCounts.count) elements) must have \
exactly as many elements as <targets> (\(targets.count) elements).
""")
        }

        guard dsymPaths.count == targets.count else {
            throw ValidationError("""
<dsym-paths> (\(dsymPaths.count) elements) must have exactly as many elements \
as <targets> (\(targets.count) elements).
""")
        }
    }
}

// MARK: - TargetArguments

struct TargetArguments: Equatable {
    let xcodeConfigurations: [String]
    let productType: PBXProductType
    let packageBinDir: String

    /// e.g. "generator" or "App"
    let productName: String

    /// e.g. "generator_codesigned" or "App.app"
    let productBasename: String

    let moduleName: String

    let platform: Platform
    let osVersion: SemanticVersion
    let arch: String

    let buildSettingsFile: URL?
    let hasCParams: Bool
    let hasCxxParams: Bool

    // FIXME: Extract to `Inputs` type
    let srcs: [BazelPath]
    let nonArcSrcs: [BazelPath]
    let hdrs: [BazelPath]
    let resources: [BazelPath]
    let folderResources: [BazelPath]

    let dSYMPathsBuildSetting: String
}

extension TargetsArguments {
    func toTargetArguments() -> [TargetID: TargetArguments] {
        var folderResourcesStartIndex = folderResources.startIndex
        var hdrsStartIndex = hdrs.startIndex
        var nonArcSrcsStartIndex = nonArcSrcs.startIndex
        var resourcesStartIndex = resources.startIndex
        var srcsStartIndex = srcs.startIndex
        var xcodeConfigurationsStartIndex = xcodeConfigurations.startIndex
        var targetArgumentKeysWithValues: [(TargetID, TargetArguments)] = []
        for targetIndex in targets.indices {
            // Collect xcodeConfigurations, srcs, nonArcSrcs, hdrs, resources,
            // and folderResources for this target
            let xcodeConfigurations = xcodeConfigurations.slicedBy(
                targetIndex: targetIndex,
                counts: xcodeConfigurationCounts,
                startIndex: &xcodeConfigurationsStartIndex
            )
            let srcs = srcs.slicedBy(
                targetIndex: targetIndex,
                counts: srcsCounts,
                startIndex: &srcsStartIndex
            )
            let nonArcSrcs = nonArcSrcs.slicedBy(
                targetIndex: targetIndex,
                counts: nonArcSrcsCounts,
                startIndex: &nonArcSrcsStartIndex
            )
            let hdrs = hdrs.slicedBy(
                targetIndex: targetIndex,
                counts: hdrsCounts,
                startIndex: &hdrsStartIndex
            )
            let resources = resources.slicedBy(
                targetIndex: targetIndex,
                counts: resourcesCounts,
                startIndex: &resourcesStartIndex
            )
            let folderResources = folderResources.slicedBy(
                targetIndex: targetIndex,
                counts: folderResourcesCounts,
                startIndex: &folderResourcesStartIndex
            )

            targetArgumentKeysWithValues.append(
                (
                    targets[targetIndex],
                    .init(
                        xcodeConfigurations: xcodeConfigurations,
                        productType: productTypes[targetIndex],
                        packageBinDir: packageBinDirs[targetIndex],
                        productName: productNames[targetIndex],
                        productBasename: productBasenames[targetIndex],
                        moduleName: moduleNames[targetIndex],
                        platform: platforms[targetIndex],
                        osVersion: osVersions[targetIndex],
                        arch: archs[targetIndex],
                        buildSettingsFile:
                            buildSettingsFiles[targetIndex],
                        hasCParams: hasCParams[targetIndex],
                        hasCxxParams: hasCxxParams[targetIndex],
                        srcs: srcs,
                        nonArcSrcs: nonArcSrcs,
                        hdrs: hdrs,
                        resources: resources,
                        folderResources: folderResources,
                        dSYMPathsBuildSetting: dsymPaths[targetIndex]
                    )
                )
            )
        }

        return Dictionary(uniqueKeysWithValues: targetArgumentKeysWithValues)
    }
}

private extension Array {
    func slicedBy<CountsCollection>(
        targetIndex: Int,
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
