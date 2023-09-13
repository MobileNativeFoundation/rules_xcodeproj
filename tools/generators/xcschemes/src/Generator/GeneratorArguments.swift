import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj
import XCScheme

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to the directory where `.xcscheme` files should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: true) }
        )
        var outputDirectory: URL

        @Argument(help: "Name of the default Xcode configuration.")
        var defaultXcodeConfiguration: String

        @Argument(help: "Absolute path to the Bazel workspace.")
        var workspace: String

        @Argument(help: """
Bazel workspace relative path to where the final `.xcodeproj` will be output.
""")
        var installPath: String

        @Argument(
            help: """
Path to a file that contains a JSON representation of \
`[TargetID: ExtensionPointIdentifier]`.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var extensionPointIdentifiersFile: URL

        @Option(
            parsing: .upToNextOption,
            help: "Path to the consolidation maps.",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var consolidationMaps: [URL]

        @Option(
            parsing: .upToNextOption,
            help: "Pairs of <target> <extension-host> target IDs."
        )
        private var targetAndExtensionHosts: [TargetID] = []

        @Option(
            parsing: .upToNextOption,
            help: """
Lists of <target> <additional-target> ... target IDs, with \
--additional-targets-counts determining how many <additional-target> to \
consume per <target>.
"""
        )
        private var additionalTargets: [TargetID] = []

        @Option(
            parsing: .upToNextOption,
            help: """
The number of additional targets per target to consume in --additional-targets.
"""
        )
        private var additionalTargetCounts: [Int] = []

        @OptionGroup var customSchemesArguments: CustomSchemesArguments

        mutating func validate() throws {
            guard targetAndExtensionHosts.count.isMultiple(of: 2) else {
                throw ValidationError("""
<target-and-extension-hosts> (\(targetAndExtensionHosts.count) elements) must \
be <target> and <extension-hosts> pairs.
""")
            }

            let additionalTargetsCount = additionalTargetCounts.count +
                additionalTargetCounts.reduce(0, +)
            guard additionalTargets.count == additionalTargetsCount else {
                throw ValidationError("""
<additional-targets> (\(additionalTargets.count) elements) must have \
\(additionalTargetsCount) elements (\(additionalTargetCounts.count) lists).
""")
            }
        }
    }
}

extension Generator.Arguments {
    func calculateTransitivePreviewReferences(
        targetsByID: [TargetID: Target]
    ) throws -> [TargetID: [BuildableReference]] {
        var keysWithValues: [(TargetID, [BuildableReference])] = []

        var index = 0
        for count in additionalTargetCounts {
            let id = additionalTargets[index]
            index += 1
            let additionalTargets = additionalTargets[index..<(index + count)]
            index += count
            keysWithValues.append(
                (
                    id,
                    try additionalTargets.map { id in
                        return try targetsByID
                            .value(for: id, context: "Additional target")
                            .buildableReference
                    }
                )
            )
        }

        return Dictionary(uniqueKeysWithValues: keysWithValues)
    }

    func calculateExtensionHostIDs() -> [TargetID: [TargetID]] {
        var ret: [TargetID: [TargetID]] = [:]
        for index in stride(
            from: 0,
            to: targetAndExtensionHosts.count - 1,
            by: 2
        ) {
            ret[targetAndExtensionHosts[index], default: []]
                .append(targetAndExtensionHosts[index+1])
        }
        return ret
    }
}
