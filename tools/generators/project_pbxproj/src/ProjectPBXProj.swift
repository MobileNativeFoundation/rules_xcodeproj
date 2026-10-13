import ArgumentParser
import Darwin
import ToolCommon

@main
struct ProjectPBXProj: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "project_pbxproj",
        abstract: """
Assembles the 'project.pbxproj' file from 'PBXProj' partials.
"""
    )

    @OptionGroup var arguments: Generator.Arguments

    @Flag(help: "Whether to colorize console output.")
    var colorize = false

    static func main() async {
        await parseAsRootSupportingParamsFile()
    }

    func run() throws {
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: colorize
        )

        let generator = Generator()

        do {
            try generator.generate(arguments: arguments)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }
}
