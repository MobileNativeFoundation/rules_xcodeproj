import ArgumentParser
import Darwin
import Foundation
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
        var output = StdoutOutputStream()
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: output,
            colorize: colorDiagnostics
        )

        let calculator = OutputGroupsCalculator(logger: logger)

        do {
            let groups = try await calculator.calculateOutputGroups(arguments: arguments)
            print(groups, to: &output)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }
}
