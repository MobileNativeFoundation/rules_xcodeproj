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

    // MARK: - consumeArgUnlessNull

    public mutating func consumeArgUnlessNull<Output> (
        _ name: String,
        as type: Output.Type,
        in url: URL? = nil,
        transform: (String) throws -> Output,
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
        guard rawArg != "\0" else {
            return nil
        }
        return try transform(rawArg)
    }

    public mutating func consumeArgUnlessNull<Output: ExpressibleByArgument>(
        _ name: String,
        as type: Output.Type = String.self,
        in url: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Output? {
        return try consumeArgUnlessNull(
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

    // MARK: - consumeArgs

    public mutating func consumeArgs<Output>(
        _ name: String,
        as type: Output.Type,
        count: Int,
        in url: URL? = nil,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        var args: [Output] = []
        for _ in (0..<count) {
            let arg = try consumeArg(
                name,
                as: type,
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
        _ name: String,
        as type: Output.Type,
        count: Int,
        in url: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        return try consumeArgs(
            name,
            as: type,
            count: count,
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

    public mutating func consumeArgs<Output>(
        _ name: String,
        as type: Output.Type,
        in url: URL? = nil,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        let count = try consumeArg("\(name)-count", as: Int.self, in: url)

        return try consumeArgs(
            name,
            as: type,
            count: count,
            in: url,
            transform: transform,
            file: file,
            line: line
        )
    }

    public mutating func consumeArgs<Output: ExpressibleByArgument>(
        _ name: String,
        as type: Output.Type = String.self,
        in url: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        let count = try consumeArg("\(name)-count", as: Int.self, in: url)

        return try consumeArgs(
            name,
            as: type,
            count: count,
            in: url,
            file: file,
            line: line
        )
    }

    // MARK: - consumeArgsUntilNull

    public mutating func consumeArgsUntilNull<Output>(
        _ name: String,
        as type: Output.Type,
        in url: URL? = nil,
        transform: (String) throws -> Output,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        var args: [Output] = []
        while true {
            guard let arg = try consumeArgUnlessNull(
                name,
                as: type,
                in: url,
                transform: transform,
                file: file,
                line: line
            ) else {
                break
            }
            args.append(arg)
        }
        return args
    }

    public mutating func consumeArgsUntilNull<Output: ExpressibleByArgument>(
        _ name: String,
        as type: Output.Type = String.self,
        in url: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [Output] {
        return try consumeArgsUntilNull(
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
}

private extension Optional where Wrapped == URL {
    func prefixMessage(_ message: String) -> String {
        guard let url = self else {
            return message
        }
        return url.prefixMessage(message)
    }
}
