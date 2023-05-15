import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to where the BazelDependencies 'PBXProj' partial should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var outputPath: URL

        @Argument(help: "Path to the target IDs list file.")
        var targetIdsFile: String

        @Argument(help: "Path to the index_import executable.")
        var indexImport: String

        @Option(
            parsing: .upToNextOption,
            help: "Names of the Xcode configurations the project is using."
        )
        var xcodeConfigurations: [String]

        @Option(help: "Name of the default Xcode configuration.")
        var defaultXcodeConfiguration: String?

        @Option(
            parsing: .upToNextOption,
            help: "Names of the platforms the project is using."
        )
        var platforms: [Platform]

        @Option(
            help: "Path to a file containing a pre-build script.",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var preBuildScript: URL?

        @Option(
            help: "Path to a file containing a post-build script.",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var postBuildScript: URL?

        func validate() throws {
            if let defaultXcodeConfiguration = defaultXcodeConfiguration {
                guard
                    xcodeConfigurations.contains(defaultXcodeConfiguration)
                else {
                    throw ValidationError("""
'default-xcode-configuration' must be from one of the values specified with \
'xcode-configurations'.
""")
                }
            }
        }
    }
}
