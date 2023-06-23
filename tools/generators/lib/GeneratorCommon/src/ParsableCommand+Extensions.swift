import ArgumentParser
import Foundation

extension ParsableCommand {
    public static func parseAsRootSupportingParamsFiles() async {
        do {
            var arguments: [String] = []
            for argument in CommandLine.arguments.dropFirst() {
                if argument.starts(with: "@") {
                    try await parseParamsFile(
                        String(argument.dropFirst()),
                        arguments: &arguments
                    )
                } else {
                    arguments.append(argument)
                }
            }

          var command = try parseAsRoot(arguments)
          try command.run()
        } catch {
          exit(withError: error)
        }
    }

    private static func parseParamsFile(
        _ path: String,
        arguments: inout [String]
    ) async throws {
        for try await line in URL(fileURLWithPath: path).lines {
            arguments.append(line)
        }
    }
}
