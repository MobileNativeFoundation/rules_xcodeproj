import ArgumentParser
import Foundation
import ToolCommon

@main
struct PBXProjectTargets: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "pbxtargets",
        abstract: "Generates the 'PBXNativeTarget's 'PBXProj' partials."
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
