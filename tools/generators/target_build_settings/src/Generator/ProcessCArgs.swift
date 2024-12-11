import Foundation
import PBXProj
import ToolCommon

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
            executionRootFilePath: URL?
        ) async throws -> Bool {
            try await callable(
                /*argsStream:*/ argsStream,
                /*buildSettings:*/ &buildSettings,
                executionRootFilePath,
                /*processCcArgs:*/ processCcArgs,
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
        _ executionRootFilePath: URL?,
        _ processCcArgs: Generator.ProcessCcArgs,
        _ write: Write
    ) async throws -> Bool

    static func defaultCallable(
        argsStream: AsyncThrowingStream<String, Error>,
        buildSettings: inout [(key: String, value: String)],
        executionRootFilePath: URL?,
        processCcArgs: Generator.ProcessCcArgs,
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
            argsStream: argsStream
        )

        var PROJECT_DIR = ""
        if let execRootURL = executionRootFilePath {
            PROJECT_DIR = try String(contentsOf: execRootURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        } 
        let BAZEL_OUT = PROJECT_DIR + "/bazel-out"

        let (DEVELOPER_DIR, SDKROOT) = (ProcessInfo.processInfo.environment["DEVELOPER_DIR"] ?? "", ProcessInfo.processInfo.environment["SDKROOT"] ?? "")
        guard !DEVELOPER_DIR.isEmpty, !SDKROOT.isEmpty, !PROJECT_DIR.isEmpty else {
            throw PreconditionError(message: """
`DEVELOPER_DIR`, `SDKROOT`, and `PROJECT_DIR` must be set in the environment.
""")
        }
        
        let environmentVariables: [String: String] = [
            "$(PROJECT_DIR)": PROJECT_DIR,
            "$(BAZEL_OUT)": BAZEL_OUT,
            "$(DEVELOPER_DIR)": DEVELOPER_DIR,
            "$(SDKROOT)": SDKROOT
        ]

        let content = try args.map { arg -> String in
            var newArg = arg
            for (key, value) in environmentVariables {
                newArg = newArg.replacingOccurrences(of: key, with: value)
            }
            return newArg + "\n"
        }.joined()

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
"@$(BAZEL_OUT)\#(outputPath.dropFirst(9)) \#
-D_FORTIFY_SOURCE=\#(fortifySourceLevel)"
"""#
                )
            )
            buildSettings.append(
                (
                    "ASAN_OTHER_CFLAGS__YES",
                    #"""
"@$(BAZEL_OUT)\#(outputPath.dropFirst(9))"
"""#
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
                    #"""
"@$(BAZEL_OUT)\#(outputPath.dropFirst(9))"
"""#
                )
            )
        }

        return hasDebugInfo
    }
}
