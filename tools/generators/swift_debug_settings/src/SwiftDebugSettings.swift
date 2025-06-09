import Darwin
import Foundation
import ToolCommon

@main
struct SwiftDebugSettings {
    static func main() async {
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: false
        )

        do {
            // First argument is executable name
            let rawArguments = CommandLine.arguments.dropFirst()
            
            // Check for a params file
            var arguments: ArraySlice<String>
            if let arg = rawArguments.first, rawArguments.count == 1,
               arg.starts(with: "@")
            {
                arguments = try await parseParamsFile(String(arg.dropFirst()))
            } else {
                arguments = ArraySlice(rawArguments)
            }

            if try arguments.consumeArg("colorize", as: Bool.self) {
                logger.enableColors()
            }

            try await Generator().generate(rawArguments: arguments)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }
    
    private static func parseParamsFile(
        _ path: String
    ) async throws -> ArraySlice<String> {
        return try await ArraySlice(URL(fileURLWithPath: path).allLines.collect())
    }
}
