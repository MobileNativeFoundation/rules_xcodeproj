import ArgumentParser
import Foundation
import GeneratorCommon

@main
struct PBXProjectPrefix: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "pbxproject_prefix",
        abstract: "Generates the 'PBXProject' prefix 'PBXProj' partial."
    )

    @OptionGroup var arguments: Generator.Arguments

    @Flag(help: "Whether to colorize console output.")
    var colorize = false

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
