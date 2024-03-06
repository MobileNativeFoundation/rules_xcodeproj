import ArgumentParser
import Darwin
import ToolCommon

@main
struct CalculateOutputGroups: AsyncParsableCommand {
    @Argument(
        help: "Value of the 'COLOR_DIAGNOSTICS' environment variable.",
        transform: { $0 == "YES" }
    )
    var colorDiagnostics: Bool

    @OptionGroup var arguments: OutputGroupsCalculator.Arguments

    func run() async throws {
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: colorDiagnostics
        )

        let calculator = OutputGroupsCalculator()

        do {
            try await calculator.calculateOutputGroups(arguments: arguments)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }
}
