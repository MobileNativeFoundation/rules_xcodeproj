import Darwin
import ToolCommon

@main
struct TargetBuildSettings {
    static func main() async {
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: false
        )

        do {
            // First argument is executable name
            var rawArguments = CommandLine.arguments.dropFirst()

            if try rawArguments.consumeArg("colorize", as: Bool.self) {
                logger.enableColors()
            }

            try await Generator().generate(rawArguments: rawArguments)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }
}
