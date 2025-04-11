import ArgumentParser
import Foundation

extension OutputGroupsCalculator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: "Value of the 'XCODE_VERSION_ACTUAL' environment variable."
        )
        var xcodeVersionActual: Int

        @Argument(
            help: """
Value of the 'OBJROOT' build setting when 'ENABLE_PREVIEWS = NO'.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: true) }
        )
        var nonPreviewObjRoot: URL

        @Argument(
            help: """
Value of 'nonPreviewObjRoot' when 'INDEX_ENABLE_BUILD_ARENA = NO'.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: true) }
        )
        var baseObjRoot: URL

        @Argument(
            help: """
Path to a file that has a ctime at or after the start of the build.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var buildMarkerFile: URL

        @Argument(
            help: "Comma seperated list of output group prefixes.",
            transform: { $0.split(separator: ",").map(String.init) }
        )
        var outputGroupPrefixes: [String]
    }
}
