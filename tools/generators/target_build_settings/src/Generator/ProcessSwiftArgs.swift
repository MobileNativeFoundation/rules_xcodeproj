import Foundation
import OrderedCollections

extension Generator {
    struct ProcessSwiftArgs {
        private let parseTransitiveSwiftDebugSettings:
            ParseTransitiveSwiftDebugSettings
        private let processSwiftArg: ProcessSwiftArg
        private let processSwiftClangArg: ProcessSwiftClangArg
        private let processSwiftFrontendArg: ProcessSwiftFrontendArg

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            parseTransitiveSwiftDebugSettings:
                ParseTransitiveSwiftDebugSettings,
            processSwiftArg: ProcessSwiftArg,
            processSwiftClangArg: ProcessSwiftClangArg,
            processSwiftFrontendArg: ProcessSwiftFrontendArg,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.parseTransitiveSwiftDebugSettings =
                parseTransitiveSwiftDebugSettings
            self.processSwiftArg = processSwiftArg
            self.processSwiftClangArg = processSwiftClangArg
            self.processSwiftFrontendArg = processSwiftFrontendArg

            self.callable = callable
        }

        /// Processes all the Swift arguments.
        func callAsFunction(
            argsStream: AsyncThrowingStream<String, Error>,
            buildSettings: inout [(key: String, value: String)],
            includeSelfSwiftDebugSettings: Bool,
            previewsFrameworkPaths: String,
            previewsIncludePath: String,
            transitiveSwiftDebugSettingPaths: [URL]
        ) async throws -> (
            hasDebugInfo: Bool,
            clangArgs: [String],
            frameworkIncludes: OrderedSet<String>,
            swiftIncludes: OrderedSet<String>
        ) {
            try await callable(
                /*argsStream:*/ argsStream,
                /*buildSettings:*/ &buildSettings,
                /*includeSelfSwiftDebugSettings:*/
                    includeSelfSwiftDebugSettings,
                /*previewsFrameworkPaths:*/ previewsFrameworkPaths,
                /*previewsIncludePath:*/ previewsIncludePath,
                /*transitiveSwiftDebugSettingPaths:*/
                    transitiveSwiftDebugSettingPaths,
                /*parseTransitiveSwiftDebugSettings:*/
                    parseTransitiveSwiftDebugSettings,
                /*processSwiftArg:*/ processSwiftArg,
                /*processSwiftClangArg:*/ processSwiftClangArg,
                /*processSwiftFrontendArg:*/ processSwiftFrontendArg
            )
        }
    }
}

// MARK: - ProcessSwiftArgs.Callable

extension Generator.ProcessSwiftArgs {
    typealias Callable = (
        _ argsStream: AsyncThrowingStream<String, Error>,
        _ buildSettings: inout [(key: String, value: String)],
        _ includeSelfSwiftDebugSettings: Bool,
        _ previewsFrameworkPaths: String,
        _ previewsIncludePath: String,
        _ transitiveSwiftDebugSettingPaths: [URL],
        _ parseTransitiveSwiftDebugSettings:
            Generator.ParseTransitiveSwiftDebugSettings,
        _ processSwiftArg: Generator.ProcessSwiftArg,
        _ processSwiftClangArg: Generator.ProcessSwiftClangArg,
        _ processSwiftFrontendArg: Generator.ProcessSwiftFrontendArg
    ) async throws -> (
        hasDebugInfo: Bool,
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        swiftIncludes: OrderedSet<String>
    )

    static func defaultCallable(
        argsStream: AsyncThrowingStream<String, Error>,
        buildSettings: inout [(key: String, value: String)],
        includeSelfSwiftDebugSettings: Bool,
        previewsFrameworkPaths: String,
        previewsIncludePath: String,
        transitiveSwiftDebugSettingPaths: [URL],
        parseTransitiveSwiftDebugSettings:
            Generator.ParseTransitiveSwiftDebugSettings,
        processSwiftArg: Generator.ProcessSwiftArg,
        processSwiftClangArg: Generator.ProcessSwiftClangArg,
        processSwiftFrontendArg: Generator.ProcessSwiftFrontendArg
    ) async throws -> (
        hasDebugInfo: Bool,
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        swiftIncludes: OrderedSet<String>
    ) {
        var (
            hasDebugInfo,
            clangArgs,
            frameworkIncludes,
            onceClangArgs,
            swiftIncludes,
            includeTransitiveSwiftDebugSettings
        ) = try await _process_swift_args(
            argsStream: argsStream,
            buildSettings: &buildSettings,
            includeSelfSwiftDebugSettings: includeSelfSwiftDebugSettings,
            previewsFrameworkPaths: previewsFrameworkPaths,
            previewsIncludePath: previewsIncludePath,
            transitiveSwiftDebugSettingPaths: transitiveSwiftDebugSettingPaths,
            parseTransitiveSwiftDebugSettings:
                parseTransitiveSwiftDebugSettings,
            processSwiftArg: processSwiftArg,
            processSwiftClangArg: processSwiftClangArg,
            processSwiftFrontendArg: processSwiftFrontendArg
        )

        if includeTransitiveSwiftDebugSettings {
            try await parseTransitiveSwiftDebugSettings(
                transitiveSwiftDebugSettingPaths,
                clangArgs: &clangArgs,
                frameworkIncludes: &frameworkIncludes,
                onceClangArgs: &onceClangArgs,
                swiftIncludes: &swiftIncludes
            )
        }

        return (hasDebugInfo, clangArgs, frameworkIncludes, swiftIncludes)
    }

    private static func _process_swift_args(
        argsStream: AsyncThrowingStream<String, Error>,
        buildSettings: inout [(key: String, value: String)],
        includeSelfSwiftDebugSettings: Bool,
        previewsFrameworkPaths: String,
        previewsIncludePath: String,
        transitiveSwiftDebugSettingPaths: [URL],
        parseTransitiveSwiftDebugSettings:
            Generator.ParseTransitiveSwiftDebugSettings,
        processSwiftArg: Generator.ProcessSwiftArg,
        processSwiftClangArg: Generator.ProcessSwiftClangArg,
        processSwiftFrontendArg: Generator.ProcessSwiftFrontendArg
    ) async throws -> (
        hasDebugInfo: Bool,
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        onceClangArgs: Set<String>,
        swiftIncludes: OrderedSet<String>,
        includeTransitiveSwiftDebugSettings: Bool
    ) {
        var previousArg: String?
        var previousClangArg: String?
        var previousFrontendArg: String?
        var skipNext = 0

        // First two arguments are `swift_worker` and `clang`
        var iterator = argsStream.makeAsyncIterator()
        guard let tool = try await iterator.next(),
              tool != Generator.argsSeparator
        else {
            return (false, [], [], [], [], true)
        }
        _ = try await iterator.next()

        var args: [String] = [
            // Work around stubbed swiftc messing with Indexing setting of
            // `-working-directory` incorrectly
            "-Xcc",
            "-working-directory",
            "-Xcc",
            "$(PROJECT_DIR)",
            "-working-directory",
            "$(PROJECT_DIR)",
        ]
        var clangArgs: [String] = []
        var frameworkIncludes: OrderedSet<String> = []
        var onceClangArgs: Set<String> = []
        var swiftIncludes: OrderedSet<String> = []

        if !previewsFrameworkPaths.isEmpty {
            buildSettings.append(
                (
                    "PREVIEW_FRAMEWORK_PATHS",
                    previewsFrameworkPaths.pbxProjEscaped
                )
            )
        }

        if !previewsIncludePath.isEmpty {
            buildSettings.append(("PREVIEWS_SWIFT_INCLUDE__", #""""#))
            buildSettings.append(("PREVIEWS_SWIFT_INCLUDE__NO", #""""#))
            buildSettings.append(
                (
                    "PREVIEWS_SWIFT_INCLUDE__YES",
                    "-I\(Substring(previewsIncludePath).buildSettingPath())"
                        .pbxProjEscaped
                )
            )

            args.append("$(PREVIEWS_SWIFT_INCLUDE__$(ENABLE_PREVIEWS))")
        }

        var hasDebugInfo = false
        for try await arg in argsStream {
            guard arg != Generator.argsSeparator else {
                break
            }

            if skipNext != 0 {
                skipNext -= 1
                continue
            }

            let isClangArg = previousArg == "-Xcc"
            let isFrontendArg = previousArg == "-Xfrontend"
            let isFrontend = arg == "-Xfrontend"
            let isXcc = arg == "-Xcc"

            // Track previous argument
            defer {
                if isClangArg {
                    previousClangArg = arg
                } else if !isXcc {
                    previousClangArg = nil
                }

                if isFrontendArg {
                    previousFrontendArg = arg
                } else if !isFrontend {
                    previousFrontendArg = nil
                }

                previousArg = arg
            }

            // Handle Clang (-Xcc) args
            if isXcc {
                args.append(arg)
                continue
            }

            if isClangArg {
                try processSwiftClangArg(
                    arg,
                    previousClangArg: previousClangArg,
                    args: &args,
                    clangArgs: &clangArgs,
                    includeSelfSwiftDebugSettings:
                        includeSelfSwiftDebugSettings,
                    onceClangArgs: &onceClangArgs
                )
                continue
            }

            // Skip based on flag
            let rootArg = arg.split(separator: "=", maxSplits: 1).first!

            if let thisSkipNext = skipSwiftArgs[rootArg] {
                skipNext = thisSkipNext - 1
                continue
            }

            if isFrontendArg {
                if let thisSkipNext = skipFrontendArgs[rootArg] {
                    skipNext = thisSkipNext - 1
                    continue
                }

                // We filter out `-Xfrontend`, so we need to add it back if the
                // current arg wasn't filtered out
                args.append("-Xfrontend")

                try processSwiftFrontendArg(
                    arg,
                    previousFrontendArg: previousFrontendArg,
                    args: &args
                )
                continue
            }

            if arg == "-g" {
                hasDebugInfo = true
                continue
            }

            if !arg.hasPrefix("-") && arg.hasSuffix(".swift") {
                // These are the files to compile, not options. They are seen
                // here because of the way we collect Swift compiler options.
                // Ideally in the future we could collect Swift compiler options
                // similar to how we collect C and C++ compiler options.
                continue
            }

            try processSwiftArg(
                arg,
                previousArg: previousArg,
                previousFrontendArg: previousFrontendArg,
                args: &args,
                buildSettings: &buildSettings,
                frameworkIncludes: &frameworkIncludes,
                includeSelfSwiftDebugSettings: includeSelfSwiftDebugSettings,
                swiftIncludes: &swiftIncludes
            )
        }

        buildSettings.append(
            ("OTHER_SWIFT_FLAGS", args.joined(separator: " ").pbxProjEscaped)
        )

        // Workaround for bug in Xcode 16.3+
        // https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/3171
        buildSettings.append(
            ("SWIFT_ENABLE_EMIT_CONST_VALUES", "NO")
        )

        return (
            hasDebugInfo,
            clangArgs,
            frameworkIncludes,
            onceClangArgs,
            swiftIncludes,
            !includeSelfSwiftDebugSettings
        )
    }
}

private let skipSwiftArgs: [Substring: Int] = [
    // Xcode sets output paths
    "-emit-module-path": 2,
    "-emit-object": 1,
    "-output-file-map": 2,

    // Xcode sets these, and no way to unset them
    "-enable-bare-slash-regex": 1,
    "-module-name": 2,
    "-num-threads": 2,
    "-parse-as-library": 1,
    "-sdk": 2,
    "-target": 2,

    // We want to use Xcode's normal PCM handling
    "-module-cache-path": 2,

    // We want Xcode's normal debug handling
    "-debug-prefix-map": 2,
    "-file-prefix-map": 2,
    "-gline-tables-only": 1,

    // We want to use Xcode's normal indexing handling
    "-index-ignore-system-modules": 1,
    "-index-store-path": 2,

    // We set Xcode build settings to control these
    "-enable-batch-mode": 1,

    // We don't want to translate this for BwX
    "-emit-symbol-graph-dir": 2,

    // These are fully handled in a `previousArg` check
    "-swift-version": 1,

    // We filter out `-Xfrontend`, then add it back only if the current arg
    // wasn't filtered out
    "-Xfrontend": 1,

    // This is rules_swift specific, and we don't want to translate it for BwX
    "-Xwrapped-swift": 1,
]

private let skipFrontendArgs: [Substring: Int] = [
    // We want Xcode to control coloring
    "-color-diagnostics": 1,

    // We want Xcode's normal debug handling
    "-no-clang-module-breadcrumbs": 1,
    "-no-serialize-debugging-options": 1,
    "-serialize-debugging-options": 1,

    // We don't want to translate this for BwX
    "-emit-symbol-graph": 1,

    // Breaks compilation when indexing
    "-const-gather-protocols-file": 3,
]
