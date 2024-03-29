import ArgumentParser
import Foundation
import PBXProj

extension ElementCreator {
    struct Arguments: ParsableArguments {
        @Argument(help: "Absolute path to the Bazel workspace.")
        var workspace: String

        @Argument(help: """
Bazel workspace relative path to where the final `.xcodeproj` will be output.
""")
        var installPath: String

        @Argument(
            help: """
Path to a file that contains the absolute path to the Bazel execution root.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var executionRootFile: URL

        @Argument(
            help: """
Path to a file that contains a JSON representation of \
`[BazelPath: String]`, mapping `.xcdatamodeld` file paths to selected \
`.xcdatamodel` file names.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var selectedModelVersionsFile: URL

        @Argument(help: "Custom indent width for the project.")
        var indentWidth: UInt?

        @Argument(help: "Custom tab width for the project.")
        var tabWidth: UInt?

        @Argument(
            help: "If the project uses tabs instead of spaces.",
            transform: { $0 == "" ? nil : $0 == "1" }
        )
        var usesTabs: Bool?
    }
}
