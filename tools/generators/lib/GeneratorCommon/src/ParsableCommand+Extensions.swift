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
        return try await URL(fileURLWithPath: path).allLines.collect()
    }
}

private extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

private extension URL {
    var allLines: AsyncThrowingStream<String, Error> {
        return resourceBytes.allLines
    }
}

private extension URL.AsyncBytes {
    // Inspired by https://developer.apple.com/forums/thread/725162
    var allLines: AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let bytesTask = Task {
                var accumulator: [UInt8] = []
                var iterator = makeAsyncIterator()
                while let byte = try await iterator.next() {
                    // 10 == \n
                    if byte == 10 {
                        guard !accumulator.isEmpty else {
                            continuation.yield("")
                            continue
                        }
                        continuation.yield(
                            String(data: Data(accumulator), encoding: .utf8)!
                        )
                        accumulator = []
                    } else {
                        accumulator.append(byte)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in
                bytesTask.cancel()
            }
        }
    }
}
