extension Generator {
    struct ProcessCcArgs {
        private let processCcArg: ProcessCcArg

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            processCcArg: ProcessCcArg,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.processCcArg = processCcArg

            self.callable = callable
        }

        /// Processes all of the common flags for C or C++ arguments.
        func callAsFunction(
            argsStream: AsyncThrowingStream<String, Error>,
            separateIndexBuildOutputBase: Bool
        ) async throws -> (
            args: [String],
            hasDebugInfo: Bool,
            fortifySourceLevel: Int
        ) {
            try await callable(
                /*argsStream:*/ argsStream,
                /*processCcArg:*/ processCcArg,
                /*separateIndexBuildOutputBase:*/ separateIndexBuildOutputBase
            )
        }
    }
}

// MARK: - ProcessCcArgs.Callable

extension Generator.ProcessCcArgs {
    typealias Callable = (
        _ argsStream: AsyncThrowingStream<String, Error>,
        _ processCcArg: Generator.ProcessCcArg,
        _ separateIndexBuildOutputBase: Bool
    ) async throws -> (
        args: [String],
        hasDebugInfo: Bool,
        fortifySourceLevel: Int
    )

    static func defaultCallable(
        argsStream: AsyncThrowingStream<String, Error>,
        processCcArg: Generator.ProcessCcArg,
        separateIndexBuildOutputBase: Bool
    ) async throws -> (
        args: [String],
        hasDebugInfo: Bool,
        fortifySourceLevel: Int
    ) {
        var previousArg: String?
        var skipNext = 0

        var args: [String] = [
            "-working-directory",
            "$(PROJECT_DIR)",
        ]
        if separateIndexBuildOutputBase {
            args.append(contentsOf: [
                "-ivfsoverlay",
                "$(OBJROOT)/bazel-out-overlay.yaml",
            ])
        }

        var hasDebugInfo = false
        var fortifySourceLevel = 0
        for try await arg in argsStream {
            guard arg != Generator.argsSeparator else {
                break
            }

            if skipNext != 0 {
                skipNext -= 1
                continue
            }

            // Track previous argument
            defer {
                previousArg = arg
            }

            // Skip based on flag
            let rootArg = arg.split(separator: "=", maxSplits: 1).first!

            if let thisSkipNext = skipCCArgs[rootArg] {
                skipNext = thisSkipNext - 1
                continue
            }

            if arg == "-g" {
                hasDebugInfo = true
                continue
            }

            if arg.hasPrefix("-D_FORTIFY_SOURCE=") {
                if let level = Int(arg.dropFirst(18)) {
                    fortifySourceLevel = level
                } else {
                    fortifySourceLevel = 1
                }
                continue
            }

            try processCcArg(
                arg,
                previousArg: previousArg,
                args: &args
            )
        }

        return (args, hasDebugInfo, fortifySourceLevel)
    }
}

private let skipCCArgs: [Substring: Int] = [
    // Xcode sets these, and no way to unset them
    "-isysroot": 2,
    "-mios-simulator-version-min": 1,
    "-miphoneos-version-min": 1,
    "-mmacosx-version-min": 1,
    "-mtvos-simulator-version-min": 1,
    "-mtvos-version-min": 1,
    "-mwatchos-simulator-version-min": 1,
    "-mwatchos-version-min": 1,
    "-target": 2,

    // Xcode sets input and output paths
    "-c": 2,
    "-o": 2,

    // We set this in the generator
    "-fobjc-arc": 1,
    "-fno-objc-arc": 1,

    // We want to use Xcode's dependency file handling
    "-MD": 1,
    "-MF": 2,

    // We want to use Xcode's normal indexing handling
    "-index-ignore-system-symbols": 1,
    "-index-store-path": 2,

    // We want Xcode's normal debug handling
    "-fdebug-prefix-map": 2,

    // We want Xcode to control coloring
    "-fcolor-diagnostics": 1,

    // This is wrapped_clang specific, and we don't want to translate it for BwX
    "DEBUG_PREFIX_MAP_PWD": 1,
]
