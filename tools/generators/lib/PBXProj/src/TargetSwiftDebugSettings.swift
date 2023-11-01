import Foundation
import ToolCommon

public struct TargetSwiftDebugSettings {
    public let clangArgs: [String]
    public let frameworkIncludes: [String]
    public let swiftIncludes: [String]
}

extension TargetSwiftDebugSettings {
    static func decode(from url: URL) async throws -> Self {
        var iterator = url.lines.makeAsyncIterator()

        guard let rawClangArgsCount = try await iterator.next() else {
            throw PreconditionError(
                message: url.prefixMessage("Missing clang args count")
            )
        }
        guard let clangArgsCount = Int(rawClangArgsCount) else {
            throw PreconditionError(message: url.prefixMessage("""
Clang args count "\(rawClangArgsCount)" was not an integer
"""))
        }

        var clangArgs: [String] = []
        for index in (0..<clangArgsCount) {
            guard let arg = try await iterator.next()?.nullsToNewlines else {
                throw PreconditionError(message: url.prefixMessage("""
Too clang args. Found \(index), expected \(clangArgsCount)
"""))
            }
            clangArgs.append(arg)
        }

        guard let rawFrameworkIncludesCount = try await iterator.next()
        else {
            throw PreconditionError(
                message: url.prefixMessage("Missing framework includes count")
            )
        }
        guard let frameworkIncludesCount = Int(rawFrameworkIncludesCount)
        else {
            throw PreconditionError(message: url.prefixMessage("""
Framework includes count "\(rawFrameworkIncludesCount)" was not an integer
"""))
        }

        var frameworkIncludes: [String] = []
        for index in (0..<frameworkIncludesCount) {
            guard let include
                = try await iterator.next()?.nullsToNewlines
            else {
                throw PreconditionError(message: url.prefixMessage("""
Too few framework includes. Found \(index), expected \(frameworkIncludesCount)
"""))
            }
            frameworkIncludes.append(include)
        }

        guard let rawSwiftIncludesCount = try await iterator.next()
        else {
            throw PreconditionError(
                message: url.prefixMessage("Missing swift includes count")
            )
        }
        guard let swiftIncludesCount = Int(rawSwiftIncludesCount)
        else {
            throw PreconditionError(message: url.prefixMessage("""
Swift includes count "\(rawSwiftIncludesCount)" was not an integer
"""))
        }

        var swiftIncludes: [String] = []
        for index in (0..<swiftIncludesCount) {
            guard let include =
                try await iterator.next()?.nullsToNewlines
            else {
                throw PreconditionError(message: url.prefixMessage("""
Too few swift includes. Found \(index), expected \(swiftIncludesCount)
"""))
            }
            swiftIncludes.append(include)
        }

        return Self(
            clangArgs: clangArgs,
            frameworkIncludes: frameworkIncludes,
            swiftIncludes: swiftIncludes
        )
    }
}
