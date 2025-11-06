import Foundation
import PBXProj

extension Generator {
    struct ProcessCArgs {
        private let processCcArgs: ProcessCcArgs
        private let write: Write

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            processCcArgs: ProcessCcArgs,
            write: Write,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.processCcArgs = processCcArgs
            self.write = write

            self.callable = callable
        }

        /// Processes all the C/Objective-C arguments.
        func callAsFunction(
            argsStream: AsyncThrowingStream<String, Error>,
            buildSettings: inout [(key: String, value: String)],
            separateIndexBuildOutputBase: Bool
        ) async throws -> Bool {
            try await callable(
                /*argsStream:*/ argsStream,
                /*buildSettings:*/ &buildSettings,
                /*processCcArgs:*/ processCcArgs,
                /*separateIndexBuildOutputBase:*/ separateIndexBuildOutputBase,
                /*write:*/ write
            )
        }
    }
}

// MARK: - ProcessCArgs.Callable

extension Generator.ProcessCArgs {
    typealias Callable = (
        _ argsStream: AsyncThrowingStream<String, Error>,
        _ buildSettings: inout [(key: String, value: String)],
        _ processCcArgs: Generator.ProcessCcArgs,
        _ separateIndexBuildOutputBase: Bool,
        _ write: Write
    ) async throws -> Bool

    static func defaultCallable(
        argsStream: AsyncThrowingStream<String, Error>,
        buildSettings: inout [(key: String, value: String)],
        processCcArgs: Generator.ProcessCcArgs,
        separateIndexBuildOutputBase: Bool,
        write: Write
    ) async throws -> Bool {
        var iterator = argsStream.makeAsyncIterator()

        guard let outputPath = try await iterator.next() else {
            return false
        }

        guard outputPath != Generator.argsSeparator else {
            return false
        }

        // First argument is `wrapped_clang`
        _ = try await iterator.next()

        let (args, hasDebugInfo, fortifySourceLevel) = try await processCcArgs(
            argsStream: argsStream,
            separateIndexBuildOutputBase: separateIndexBuildOutputBase
        )

        let content = args.map { $0 + "\n" }.joined()
        try write(content, to: URL(fileURLWithPath: String(outputPath)))

        buildSettings.append(
            (
                "C_PARAMS_FILE",
                #"""
"$(BAZEL_OUT)\#(outputPath.dropFirst(9))"
"""#
            )
        )

        if fortifySourceLevel > 0 {
            // ASAN doesn't work with `-D_FORTIFY_SOURCE=1`, so we need to only
            // include that when not building with ASAN
            buildSettings.append(
                ("ASAN_OTHER_CFLAGS__", #""$(ASAN_OTHER_CFLAGS__NO)""#)
            )
            buildSettings.append(
                (
                    "ASAN_OTHER_CFLAGS__NO",
                    #"""
"@$(DERIVED_FILE_DIR)/c.compile.params \#
-D_FORTIFY_SOURCE=\#(fortifySourceLevel)"
"""#
                )
            )
            buildSettings.append(
                (
                    "ASAN_OTHER_CFLAGS__YES",
                    #""@$(DERIVED_FILE_DIR)/c.compile.params""#
                )
            )
            buildSettings.append(
                (
                    "OTHER_CFLAGS",
                    #"""
"$(ASAN_OTHER_CFLAGS__$(CLANG_ADDRESS_SANITIZER))"
"""#
                )
            )
        } else {
            buildSettings.append(
                (
                    "OTHER_CFLAGS",
                    #""@$(DERIVED_FILE_DIR)/c.compile.params""#
                )
            )
        }

        return hasDebugInfo
    }
}
