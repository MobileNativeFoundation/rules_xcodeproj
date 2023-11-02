import Foundation
import ToolCommon

public struct TargetSwiftDebugSettings: Equatable {
    public let clangArgs: [String]
    public let frameworkIncludes: [String]
    public let swiftIncludes: [String]
}

extension TargetSwiftDebugSettings {
    static func decode(from url: URL) async throws -> Self {
        var iterator = url.lines.makeAsyncIterator()

        let clangArgs = try await iterator.consumeArgs("clang args", in: url)
        let frameworkIncludes =
            try await iterator.consumeArgs("framework includes", in: url)
        let swiftIncludes =
            try await iterator.consumeArgs("swift includes", in: url)

        return Self(
            clangArgs: clangArgs,
            frameworkIncludes: frameworkIncludes,
            swiftIncludes: swiftIncludes
        )
    }
}

private extension AsyncLineSequence.AsyncIterator where Base == URL.AsyncBytes {
    mutating func consumeArgs(
        _ name: String,
        in url: URL
    ) async throws -> [String] {
        guard let rawCount = try await next() else {
            throw PreconditionError(
                message: url.prefixMessage("Missing \(name) count")
            )
        }
        guard let count = Int(rawCount) else {
            throw PreconditionError(message: url.prefixMessage("""
\(name) count "\(rawCount)" was not an integer
"""))
        }

        var args: [String] = []
        for index in (0..<count) {
            guard let arg = try await next()?.nullsToNewlines else {
                throw PreconditionError(message: url.prefixMessage("""
Too few \(name). Found \(index), expected \(count)
"""))
            }
            args.append(arg)
        }

        return args
    }
}
