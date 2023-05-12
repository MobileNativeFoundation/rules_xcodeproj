import ArgumentParser
import Foundation
import GeneratorCommon

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to where the 'pbxproject_prefix' 'PBXProj' partial should be written.
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

        @Argument(help: """
Minimum Xcode version that the generated project supports.
""")
        var minimumXcodeVersion: SemanticVersion

        @Argument(help: "Development region for the project.")
        var developmentRegion

        @Option(help: """
Populates the `ORGANIZATIONNAME` attribute for the project.
""")
        var organizationName: String?
    }
}
