import ArgumentParser
import GeneratorCommon

extension ArraySlice<String> {
    public mutating func consumeArg<Output> (
        _ type: Output.Type,
        transform: (String) throws -> Output
    ) throws -> Output {
        guard let rawArg = popFirst() else {
            throw PreconditionError(message: "Expected more arguments")
        }
        return try transform(rawArg)
    }

    private static func argumentTransform<Output: ExpressibleByArgument>(
        _ rawArg: String
    ) throws -> Output {
        guard let arg = Output(argument: rawArg) else {
            throw PreconditionError(
                message:
                    #"Failed to parse "\#(rawArg)" as \#(Output.Type.self)"#
            )
        }
        return arg
    }

    public mutating func consumeArg<Output: ExpressibleByArgument>(
        _ type: Output.Type
    ) throws -> Output {
        return try consumeArg(type, transform: Self.argumentTransform)
    }

    private mutating func consumeArg<Output>(
        _ type: Output.Type,
        transform: (String) throws -> Output,
        unless: String
    ) throws -> Output? {
        guard let rawArg = popFirst() else {
            throw PreconditionError(message: "Expected more arguments")
        }

        guard rawArg != unless else {
            return nil
        }

        return try transform(rawArg)
    }

    public mutating func consumeArgs<Output>(
        _ type: Output.Type,
        transform: (String) throws -> Output,
        terminator: String = "--"
    ) throws -> [Output] {
        var args: [Output] = []
        while let arg = try consumeArg(
            type,
            transform: transform,
            unless: terminator
        ) {
            args.append(arg)
        }
        return args
    }

    public mutating func consumeArgs<Output: ExpressibleByArgument>(
        _ type: Output.Type,
        terminator: String = "--"
    ) throws -> [Output] {
        return try consumeArgs(
            type,
            transform: Self.argumentTransform,
            terminator: terminator
        )
    }
}
