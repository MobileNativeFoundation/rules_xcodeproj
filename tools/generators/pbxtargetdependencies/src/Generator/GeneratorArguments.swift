import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to where the 'pbxtargetdependencies' 'PBXProj' partial should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var targetDependenciesOutputPath: URL

        @Argument(
            help: """
Path to where the 'pbxtargetdependencies' 'PBXProj' partial should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var targetsOutputPath: URL

        @Argument(
            help: """
Path to where the 'pbxproject_target_attributes' 'PBXProj' partial should be \
written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var targetAttributesOutputPath: URL

        @Argument(help: """
Minimum Xcode version that the generated project supports.
""")
        var minimumXcodeVersion: SemanticVersion

        @Option(
            parsing: .upToNextOption,
            help: "Pairs of <target> <test-host> target IDs."
        )
        private var targetAndTestHosts: [TargetID] = []

        @Option(
            parsing: .upToNextOption,
            help: "Pairs of <target> <watchkit-extension> target IDs."
        )
        private var targetAndWatchKitExtensions: [TargetID] = []

        @OptionGroup var consolidationMapsArguments: ConsolidationMapsArguments

        mutating func validate() throws {
            guard targetAndTestHosts.count.isMultiple(of: 2) else {
                throw ValidationError("""
<target-and-test-hosts> (\(targetAndTestHosts.count) elements) must be \
<target> and <test-host> pairs.
""")
            }
        }
    }
}

extension Generator.Arguments {
    var testHosts: [TargetID: TargetID] {
        return Dictionary(
            uniqueKeysWithValues:
                stride(from: 0, to: targetAndTestHosts.count - 1, by: 2)
                .lazy
                .map { index in
                    return (
                        targetAndTestHosts[index],
                        targetAndTestHosts[index+1]
                    )
                }
        )
    }

    var watchKitExtensions: [TargetID: TargetID] {
        return Dictionary(
            uniqueKeysWithValues:
                stride(
                    from: 0,
                    to: targetAndWatchKitExtensions.count - 1,
                    by: 2
                )
                .lazy
                .map { index in
                    return (
                        targetAndWatchKitExtensions[index],
                        targetAndWatchKitExtensions[index+1]
                    )
                }
        )
    }
}
