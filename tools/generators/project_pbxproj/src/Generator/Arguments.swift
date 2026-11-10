import ArgumentParser
import Foundation

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: "Path to where the 'project.pbxproj' file should be written.",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var outputPath: URL

        @Argument(
            help: """
Paths to the 'PBXProj' partials, in the order they need to be concatenated.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var partials: [URL]
    }
}
