import ArgumentParser
import Foundation
import ToolCommon

extension ArraySlice<String> {
    // MARK: - consumeArg

    public mutating func consumeArg<Output> (
        _ type: Output.Type,
        in url: URL,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output {
        guard let rawArg = popFirst() else {
            throw PreconditionError(
                message: #""\#(url.path)": Expected more arguments"#,
                file: file,
                line: line
            )
        }
        return try transform(rawArg)
    }

    private static func argumentTransform<Output: ExpressibleByArgument>(
        _ rawArg: String,
        in url: URL,
        file: StaticString,
        line: UInt
    ) throws -> Output {
        guard let arg = Output(argument: rawArg) else {
            throw PreconditionError(
                message: #"""
"\#(url.path)": Failed to parse "\#(rawArg)" as \#(Output.Type.self)
"""#,
                file: file,
                line: line
            )
        }
        return arg
    }

    public mutating func consumeArg<Output: ExpressibleByArgument>(
        _ type: Output.Type,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output {
        return try consumeArg(
            type,
            in: url,
            transform: { arg in
                return try Self.argumentTransform(
                    arg,
                    in: url,
                    file: file,
                    line: line
                )
            },
            file: file,
            line: line
        )
    }

    private mutating func consumeArg<Output>(
        _ type: Output.Type,
        in url: URL,
        transform: (String) throws -> Output,
        unless: String,
        file: StaticString,
        line: UInt
    ) throws -> Output? {
        guard let rawArg = popFirst() else {
            throw PreconditionError(
                message: #""\#(url.path)": Expected more arguments"#,
                file: file,
                line: line
            )
        }

        guard rawArg != unless else {
            return nil
        }

        return try transform(rawArg)
    }

    public mutating func consumeArg(
        _ type: Bool.Type,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Bool {
        return try consumeArg(
            Bool.self,
            in: url,
            transform: { $0 == "1" },
            file: file,
            line: line
        )
    }

    // MARK: - consumeArgs

    public mutating func consumeArgs<Output>(
        _ type: Output.Type,
        count: Int,
        in url: URL,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        var args: [Output] = []
        for _ in (0..<count) {
            let arg = try consumeArg(
                type,
                in: url,
                transform: transform,
                file: file,
                line: line
            )
            args.append(arg)
        }
        return args
    }

    public mutating func consumeArgs<Output: ExpressibleByArgument>(
        _ type: Output.Type,
        count: Int,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        return try consumeArgs(
            type,
            count: count,
            in: url,
            transform: { arg in
                return try Self.argumentTransform(
                    arg,
                    in: url,
                    file: file,
                    line: line
                )
            },
            file: file,
            line: line
        )
    }

    public mutating func consumeArgs<Output>(
        _ type: Output.Type,
        in url: URL,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        let count = try consumeArg(Int.self, in: url)

        return try consumeArgs(
            type,
            count: count,
            in: url,
            transform: transform,
            file: file,
            line: line
        )
    }

    public mutating func consumeArgs<Output: ExpressibleByArgument>(
        _ type: Output.Type,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        let count = try consumeArg(Int.self, in: url)

        return try consumeArgs(
            type,
            count: count,
            in: url,
            file: file,
            line: line
        )
    }
}
