import ArgumentParser
import Foundation
import PBXProj

extension ElementCreator {
    struct Arguments: ParsableArguments {
        @Argument(help: "Absolute path to the Bazel workspace.")
        var workspace: String

        @Argument(
            help: """
Path to a file that contains the absolute path to the Bazel execution root.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var executionRootFile: URL
    }
}
