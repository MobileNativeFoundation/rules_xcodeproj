import ArgumentParser
import Foundation
import GeneratorCommon

@main
struct BazelDependencies: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "bazel_dependencies",
        abstract: "Generates the BazelDependencies 'PBXProj' partial."
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
