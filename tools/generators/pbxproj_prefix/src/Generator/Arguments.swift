import ArgumentParser
import Foundation
import GeneratorCommon

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

        @Argument(help: "`xcodeproj.build_mode`.")
        var buildMode: BuildMode

        @Argument(help: """
Minimum Xcode version that the generated project supports.
""")
        var minimumXcodeVersion: SemanticVersion

        @Argument(help: "Development region for the project.")
        var developmentRegion: String

        @Option(help: """
Populates the `ORGANIZATIONNAME` attribute for the project.
""")
        var organizationName: String?

        @Option(
            parsing: .upToNextOption,
            help: "Names of the Xcode configurations the project is using."
        )
        var xcodeConfigurations: [String]

        @Option(help: "Name of the default Xcode configuration.")
        var defaultXcodeConfiguration: String?
    }
}
