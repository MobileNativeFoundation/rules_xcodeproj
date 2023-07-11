import ArgumentParser
import Foundation

extension ParsableCommand {
    public static func parseAsRootSupportingParamsFile() async {
        do {
            let rawArguments = CommandLine.arguments.dropFirst()

            let arguments: [String]
            if let arg = rawArguments.first, rawArguments.count == 1,
               arg.starts(with: "@")
            {
                arguments = try await parseParamsFile(String(arg.dropFirst()))
            } else {
                arguments = Array(rawArguments)
            }

            var command = try parseAsRoot(arguments)

            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            exit(withError: error)
        }
    }

    private static func parseParamsFile(
        _ path: String
    ) async throws -> [String] {
        return try await URL(fileURLWithPath: path).lines.collect()
    }
}

private extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}
