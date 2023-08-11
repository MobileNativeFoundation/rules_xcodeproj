import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to where the 'pbxproj_prefix' 'PBXProj' partial should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var outputPath: URL

        @Argument(help: "Absolute path to the Bazel workspace.")
        var workspace: String

        @Argument(
            help: """
Path to a file that contains the absolute path to the Bazel execution root.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var executionRootFile: URL

        @Argument(help: "Path to the target IDs list file.")
        var targetIdsFile: String

        @Argument(help: "Path to the index_import executable.")
        var indexImport: String

        @Argument(
            help: """
Path to a file that contains a string for the `RESOLVED_REPOSITORIES` build \
setting.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var resolvedRepositoriesFile: URL

        @Argument(help: "`xcodeproj.build_mode`.")
        var buildMode: BuildMode

        @Argument(help: """
Minimum Xcode version that the generated project supports.
""")
        var minimumXcodeVersion: SemanticVersion

        @Argument(help: "Name of the default Xcode configuration.")
        var defaultXcodeConfiguration: String

        @Argument(help: "Development region for the project.")
        var developmentRegion: String

        @Option(help: """
Populates the `ORGANIZATIONNAME` attribute for the project.
""")
        var organizationName: String?

        @Option(
            parsing: .upToNextOption,
            help: "Names of the platforms the project is using."
        )
        var platforms: [Platform]

        @Option(
            parsing: .upToNextOption,
            help: "Names of the Xcode configurations the project is using."
        )
        var xcodeConfigurations: [String]

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
    }
}
