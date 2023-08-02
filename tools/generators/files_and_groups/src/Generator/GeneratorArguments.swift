import ArgumentParser
import Foundation
import PBXProj

extension Generator {
    struct Arguments: ParsableArguments {
        @Argument(
            help: """
Path to where the 'pbxproject_known_regions' 'PBXProj' partial should be \
written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var knownRegionsOutputPath: URL

        @Argument(
            help: """
Path to where the 'files_and_groups' 'PBXProj' partial should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var filesAndGroupsOutputPath: URL

        @Argument(
            help: """
Path to where the 'resolved_repositories' file should be written.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var resolvedRepositoriesOutputPath: URL

        @OptionGroup var elementCreatorArguments: ElementCreator.Arguments

        @Argument(help: "Development region for the project.")
        var developmentRegion: String

        @Flag(
            help: "Whether to add the Base region to 'PBXProject.knownRegions'."
        )
        var useBaseInternationalization = false

        @Flag(help: "Whether the compile stub is needed.")
        var compileStubNeeded = false

        @Option(
            parsing: .upToNextOption,
            help: """
Paths to where serialized '[Identifiers.BuildFile.SubIdentifiers]' should be \
read from.
""",
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )
        var buildFileSubIdentifiersFiles: [URL]

        @Option(
            parsing: .upToNextOption,
            help: """
Paths to files to include in the project. The paths are relative to the Bazel \
execution root.
"""
        )
        var filePaths: [BazelPath] = []

        @Option(
            parsing: .upToNextOption,
            help: """
Paths to folders to include in the project. The paths are relative to the \
Bazel execution root.
""",
            transform: { BazelPath($0, isFolder: true) }
        )
        var folderPaths: [BazelPath] = []
    }
}
