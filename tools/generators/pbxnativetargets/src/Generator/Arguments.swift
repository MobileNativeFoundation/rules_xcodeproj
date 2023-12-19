import ArgumentParser
import Foundation
import PBXProj
import ToolCommon

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to where the 'pbxnativetargets' 'PBXProj' partial should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var targetsOutputPath: URL

        @Argument(
            help: """
Path to where the serialized '[Identifiers.BuildFile.SubIdentifiers]' should \
be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var buildFileSubIdentifiersOutputPath: URL

        @Argument(
            help: "Path to the consolidation map.",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var consolidationMap: URL

        @Argument(
            help: """
Path to a file containing inputs for `[TargetID: TargetArgument]`.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var targetArgumentsFile: URL

        @Argument(
            help: """
Path to a file containing inputs for `[TargetID: TopLevelTargetAttributes]`.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var topLevelTargetAttributesFile: URL

        @Argument(
            help: """
Path to a file containing inputs for `[TargetID: Target.UnitTestHost]`.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var unitTestHostAttributesFile: URL

        @Argument(help: "Name of the default Xcode configuration.")
        var defaultXcodeConfiguration: String
    }
}
