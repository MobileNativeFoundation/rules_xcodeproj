import ArgumentParser
import Foundation
import GeneratorCommon

@main
struct PBXProjPrefix: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "pbxproj_prefix",
        abstract: "Generates the 'PBXProj' prefix partial."
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
