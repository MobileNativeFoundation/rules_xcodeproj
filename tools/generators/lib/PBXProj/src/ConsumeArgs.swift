import ArgumentParser
import Foundation
import ToolCommon

extension ArraySlice<String> {
    // MARK: - consumeArg

    public mutating func consumeArg<Output> (
        _ name: String,
        as type: Output.Type,
        in url: URL? = nil,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output {
        guard let rawArg = popFirst() else {
            throw PreconditionError(
                message: url.prefixMessage("Missing <\(name)>"),
                file: file,
                line: line
            )
        }
        return try transform(rawArg)
    }

    private static func argumentTransform<Output: ExpressibleByArgument>(
        _ rawArg: String,
        name: String,
        in url: URL?,
        file: StaticString,
        line: UInt
    ) throws -> Output {
        guard let arg = Output(argument: rawArg) else {
            throw PreconditionError(
                message: url.prefixMessage("""
Failed to parse "\(rawArg)" as \(Output.Type.self) for <\(name)>
"""),
                file: file,
                line: line
            )
        }
        return arg
    }

    public mutating func consumeArg<Output: ExpressibleByArgument>(
        _ name: String,
        as type: Output.Type = String.self,
        in url: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output {
        return try consumeArg(
            name,
            as: type,
            in: url,
            transform: { arg in
                return try Self.argumentTransform(
                    arg,
                    name: name,
                    in: url,
                    file: file,
                    line: line
                )
            },
            file: file,
            line: line
        )
    }

    public mutating func consumeArg(
        _ name: String,
        as type: Bool.Type,
        in url: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Bool {
        return try consumeArg(
            name,
            as: Bool.self,
            in: url,
            transform: { $0 == "1" },
            file: file,
            line: line
        )
    }

    // MARK: - consumeArgUnlessTerminator

    public mutating func consumeArgUnlessTerminator<Output> (
        _ name: String,
        as type: Output.Type,
        in url: URL? = nil,
        transform: (String) throws -> Output,
        terminator: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output? {
        guard let rawArg = popFirst() else {
            throw PreconditionError(
                message: url.prefixMessage("Missing <\(name)>"),
                file: file,
                line: line
            )
        }
        guard rawArg != terminator else {
            return nil
        }
        return try transform(rawArg)
    }

    public mutating func consumeArgUnlessTerminator<Output: ExpressibleByArgument>(
        _ name: String,
        as type: Output.Type = String.self,
        in url: URL? = nil,
        terminator: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output? {
        return try consumeArgUnlessTerminator(
            name,
            as: type,
            in: url,
            transform: { arg in
                return try Self.argumentTransform(
                    arg,
                    name: name,
                    in: url,
                    file: file,
                    line: line
                )
            },
            terminator: terminator,
            file: file,
            line: line
        )
    }

    // MARK: - consumeArgs

    public mutating func consumeArgs<Output>(
        _ name: String,
        as type: Output.Type,
        in url: URL? = nil,
        transform: (String) throws -> Output,
        terminator: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        var args: [Output] = []
        while true {
            guard let arg = try consumeArgUnlessTerminator(
                name,
                as: type,
                in: url,
                transform: transform,
                terminator: terminator,
                file: file,
                line: line
            ) else {
                break
            }
            args.append(arg)
        }
        return args
    }

    public mutating func consumeArgs<Output: ExpressibleByArgument>(
        _ name: String,
        as type: Output.Type = String.self,
        in url: URL? = nil,
        terminator: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        return try consumeArgs(
            name,
            as: type,
            in: url,
            transform: { arg in
                return try Self.argumentTransform(
                    arg,
                    name: name,
                    in: url,
                    file: file,
                    line: line
                )
            },
            terminator: terminator,
            file: file,
            line: line
        )
    }
}

private extension Optional where Wrapped == URL {
    func prefixMessage(_ message: String) -> String {
        guard let url = self else {
            return message
        }
        return url.prefixMessage(message)
    }
}
