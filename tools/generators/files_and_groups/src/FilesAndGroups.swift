import ArgumentParser
import Foundation
import GeneratorCommon

@main
struct FilesAndGroups: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "files_and_groups",
        abstract: "Generates the file and groups 'PBXProj' partials."
    )

    @OptionGroup var arguments: Generator.Arguments

    @Flag(help: "Whether to colorize console output.")
    var colorize = false

    static func main() async {
        await parseAsRootSupportingParamsFile()
    }

    func run() async throws {
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: colorize
        )

        let generator = Generator()

        do {
            try await generator.generate(arguments: arguments)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }
}
