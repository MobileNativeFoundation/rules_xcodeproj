import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

@main
struct CompilerBuildSettings {
    private static let separator = Data([0x0a]) // Newline
    private static let subSeparator = Data([0x09]) // Tab

    static func main() async {
        guard CommandLine.arguments.count > 1 else {
            let logger = DefaultLogger(
                standardError: StderrOutputStream(),
                standardOutput: StdoutOutputStream(),
                colorize: false
            )
            logger.logError(
                PreconditionError(message: "Missing <colorize>")
                    .localizedDescription
            )
            Darwin.exit(1)
        }
        let colorize = CommandLine.arguments[1] == "1"

        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: colorize
        )

        do {
            let (output, buildSettings) = try await parseArgs()

            var data = Data()

            for (key, value) in buildSettings.sorted(by: { $0.key < $1.key }) {
                data.append(Data(key.utf8))
                data.append(Self.subSeparator)
                data.append(Data(value.utf8))
                data.append(Self.separator)
            }

            try data.write(to: output)
        } catch {
            logger.logError(error.localizedDescription)
            Darwin.exit(1)
        }
    }

    private static func parseArgs() async throws -> (
        output: URL,
        buildSettings: [String: String]
    ) {
        // First 2 arguments are program name and `<colorize>`
        var rawArguments = CommandLine.arguments.dropFirst(2)

        let output = URL(
            fileURLWithPath: try rawArguments.popArgument("output-path")
        )

        let buildSettings = try await processArgs(
            rawArguments: rawArguments
        )

        return (output, buildSettings)
    }

    private static func processArgs(
        rawArguments: Array<String>.SubSequence
    ) async throws -> [String: String] {
        var rawArguments = rawArguments

        let deviceFamily = try rawArguments.popArgument("device-family")
        let extensionSafe =
            try rawArguments.popArgument("extension-safe") == "1"
        let generatesDsyms =
            try rawArguments.popArgument("generates-dsyms") == "1"
        let infoPlist = try rawArguments.popArgument("info-plist")
        let entitlements = try rawArguments.popArgument("entitlements")
        let skipCodesigning =
            try rawArguments.popArgument("skip-codesigning") == "1"
        let certificateName = try rawArguments.popArgument("certificate-name")
        let provisioningProfileName =
            try rawArguments.popArgument("provisioning-profile-name")
        let teamID = try rawArguments.popArgument("team-id")
        let provisioningProfileIsXcodeManaged = try rawArguments
            .popArgument("provisioning-profile-is-xcode-managed") == "1"
        let packageBinDir = try rawArguments.popArgument("package-bin-dir")
        let previewsFrameworkPaths =
            try rawArguments.popArgument("previews-framework-paths")
        let previewsIncludePath =
            try rawArguments.popArgument("previews-include-path")

        let args = parseArgs(rawArguments: rawArguments)
        var buildSettingsKeysWithValues: [(String, String)] = []

        if !deviceFamily.isEmpty {
            buildSettingsKeysWithValues.append(
                ("TARGETED_DEVICE_FAMILY", deviceFamily.pbxProjEscaped)
            )
        }

        if extensionSafe {
            buildSettingsKeysWithValues.append(
                ("APPLICATION_EXTENSION_API_ONLY", "YES")
            )
        }

        if !infoPlist.isEmpty {
            buildSettingsKeysWithValues.append(
                (
                    "INFOPLIST_FILE",
                    infoPlist.buildSettingPath().quoteIfNeeded().pbxProjEscaped
                )
            )
        }

        if !entitlements.isEmpty {
            buildSettingsKeysWithValues.append(
                (
                    "CODE_SIGN_ENTITLEMENTS",
                    entitlements.buildSettingPath().quoteIfNeeded()
                        .pbxProjEscaped
                )
            )

            // This is required because otherwise Xcode can fails the build
            // due to a generated entitlements file being modified by the
            // Bazel build script. We only set this for BwB mode though,
            // because when this is set, Xcode uses the entitlements as
            // provided instead of modifying them, which is needed in BwX
            // mode.
            buildSettingsKeysWithValues.append(
                ("CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION", "YES")
            )
        }

        if skipCodesigning {
            buildSettingsKeysWithValues.append(
                ("CODE_SIGNING_ALLOWED", "NO")
            )
        }

        if !certificateName.isEmpty {
            buildSettingsKeysWithValues.append(
                ("CODE_SIGN_IDENTITY", certificateName.pbxProjEscaped)
            )
        }

        if !teamID.isEmpty {
            buildSettingsKeysWithValues.append(
                ("DEVELOPMENT_TEAM", teamID.pbxProjEscaped)
            )
        }

        if !provisioningProfileName.isEmpty {
            buildSettingsKeysWithValues.append(
                (
                    "PROVISIONING_PROFILE_SPECIFIER",
                    provisioningProfileName.pbxProjEscaped
                )
            )
        }

        if provisioningProfileIsXcodeManaged {
            buildSettingsKeysWithValues.append(
                ("CODE_SIGN_STYLE", "Automatic")
            )
        }

        var buildSettings =
            Dictionary(uniqueKeysWithValues: buildSettingsKeysWithValues)

        let swiftHasDebugInfo = try await processSwiftArgs(
            rawArguments: args,
            buildSettings: &buildSettings,
            packageBinDir: packageBinDir,
            previewsFrameworkPaths: previewsFrameworkPaths,
            previewsIncludePath: previewsIncludePath
        )

        let cHasDebugInfo = try await processCArgs(
            rawArguments: args,
            buildSettings: &buildSettings
        )

        let cxxHasDebugInfo = try await processCxxArgs(
            rawArguments: args,
            buildSettings: &buildSettings
        )

        if generatesDsyms {
            buildSettings["DEBUG_INFORMATION_FORMAT"] = #""dwarf-with-dsym""#
        } else if swiftHasDebugInfo || cHasDebugInfo || cxxHasDebugInfo {
            // We don't set "DEBUG_INFORMATION_FORMAT" to "dwarf", as we set
            // that at the project level
        } else {
            buildSettings["DEBUG_INFORMATION_FORMAT"] = #""""#
        }

        return buildSettings
    }

    private static func processSwiftArgs(
        rawArguments: AsyncThrowingStream<Substring, Error>,
        buildSettings: inout [String: String],
        packageBinDir: String,
        previewsFrameworkPaths: String,
        previewsIncludePath: String
    ) async throws -> Bool {
        var previousArg: Substring? = nil
        var previousClangArg: Substring? = nil
        var previousFrontendArg: Substring? = nil
        var skipNext = 0

        // First two arguments are `swift_worker` and `clang`
        var iterator = rawArguments.makeAsyncIterator()
        guard let tool = try await iterator.next(), tool != argsSeparator else {
            return false
        }
        _ = try await iterator.next()

        var args: [Substring] = [
            // Work around stubbed swiftc messing with Indexing setting of
            // `-working-directory` incorrectly
            "-Xcc",
            "-working-directory",
            "-Xcc",
            "$(PROJECT_DIR)",
            "-working-directory",
            "$(PROJECT_DIR)",

            "-Xcc",
            "-ivfsoverlay",
            "-Xcc",
            "$(OBJROOT)/bazel-out-overlay.yaml",
            "-vfsoverlay",
            "$(OBJROOT)/bazel-out-overlay.yaml",
        ]

        if !previewsFrameworkPaths.isEmpty {
            buildSettings["PREVIEW_FRAMEWORK_PATHS"] =
                previewsFrameworkPaths.pbxProjEscaped
        }

        if !previewsIncludePath.isEmpty {
            buildSettings["PREVIEWS_SWIFT_INCLUDE__"] = #""""#
            buildSettings["PREVIEWS_SWIFT_INCLUDE__NO"] = #""""#
            buildSettings["PREVIEWS_SWIFT_INCLUDE__YES"] =
                "-I\(Substring(previewsIncludePath).buildSettingPath())"
                    .pbxProjEscaped

            args.append("$(PREVIEWS_SWIFT_INCLUDE__$(ENABLE_PREVIEWS))")
        }

        var hasDebugInfo = false
        for try await arg in rawArguments {
            guard arg != argsSeparator else {
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
                try processClangArg(
                    arg,
                    previousClangArg: previousClangArg,
                    args: &args
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

                try processFrontendArg(
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
                packageBinDir: packageBinDir
            )
        }

        buildSettings["OTHER_SWIFT_FLAGS"] =
            args.joined(separator: " ").pbxProjEscaped

        return hasDebugInfo
    }

    private static func processSwiftArg(
        _ arg: Substring,
        previousArg: Substring?,
        previousFrontendArg: Substring?,
        args: inout [Substring],
        buildSettings: inout [String: String],
        packageBinDir: String
    ) throws {
        if let compilationMode = compilationModeArgs[arg] {
            buildSettings["SWIFT_COMPILATION_MODE"] = compilationMode
            return
        }

        if previousArg == "-swift-version" {
            if arg != "5.0" {
                buildSettings["SWIFT_VERSION"] = String(arg)
            }
            return
        }

        if previousArg == "-emit-objc-header-path" {
            guard arg.hasPrefix(packageBinDir) else {
                throw UsageError(message: """
-emit-objc-header-path must be in bin dir of the target. \(arg) is not under \
\(packageBinDir)
""")
            }
            buildSettings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = String(
                arg.dropFirst(packageBinDir.count + 1).pbxProjEscaped
            )
            return
        }

        if arg.hasPrefix("-I") {
            let path = arg.dropFirst(2)
            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            let absoluteArg: Substring = "-I" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        if previousArg == "-I" {
            args.append(arg.buildSettingPath().quoteIfNeeded())
            return
        }

        if previousArg == "-F" {
            args.append(arg.buildSettingPath().quoteIfNeeded())
            return
        }

        if arg.hasPrefix("-F") {
            let path = arg.dropFirst(2)

            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            let absoluteArg: Substring = "-F" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        if arg.hasPrefix("-vfsoverlay") {
            var path = arg.dropFirst(11)

            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            if path.hasPrefix("=") {
                path = path.dropFirst()
            }

            let absoluteArg: Substring = "-vfsoverlay" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        if previousArg == "-vfsoverlay" {
            args.append(arg.buildSettingPath().quoteIfNeeded())
            return
        }

        args.append(arg.substituteBazelPlaceholders().quoteIfNeeded())
    }

    private static func processClangArg(
        _ arg: Substring,
        previousClangArg: Substring?,
        args: inout [Substring]
    ) throws {
        if arg.hasPrefix("-fmodule-map-file=") {
            let path = arg.dropFirst(18)
            let absoluteArg: Substring =
                "-fmodule-map-file=" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        for searchArg in clangSearchPathArgs {
            if arg.hasPrefix(searchArg) {
                let path = arg.dropFirst(searchArg.count)

                guard !path.isEmpty else {
                    args.append(arg)
                    return
                }

                args.append(searchArg)
                args.append("-Xcc")
                args.append(path.buildSettingPath().quoteIfNeeded())
                return
            }
        }

        if let previousClangArg,
           clangSearchPathArgs.contains(previousClangArg)
        {
            args.append(arg.buildSettingPath().quoteIfNeeded())
        }

        // `-ivfsoverlay` doesn't apply `-working_directory=`, so we need to
        // prefix it ourselves
        if previousClangArg == "-ivfsoverlay" {
            args.append(
                arg.buildSettingPath().quoteIfNeeded()
            )
            return
        }

        if arg.hasPrefix("-ivfsoverlay") {
            var path = arg.dropFirst(12)

            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            if path.hasPrefix("=") {
                path = path.dropFirst()
            }

            let absoluteArg: Substring =
                "-ivfsoverlay" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        args.append(arg.substituteBazelPlaceholders().quoteIfNeeded())
    }

    private static func processFrontendArg(
        _ arg: Substring,
        previousFrontendArg: Substring?,
        args: inout [Substring]
    ) throws {
        if let previousFrontendArg {
            if overlayArgs.contains(previousFrontendArg) {
                args.append(arg.buildSettingPath().quoteIfNeeded())
                return
            }

            if loadPluginsArgs.contains(previousFrontendArg) {
                args.append(arg.buildSettingPath().quoteIfNeeded())
                return
            }
        }

        args.append(arg.substituteBazelPlaceholders().quoteIfNeeded())
    }

    private static func processCArgs(
        rawArguments: AsyncThrowingStream<Substring, Error>,
        buildSettings: inout [String: String]
    ) async throws -> Bool {
        var iterator = rawArguments.makeAsyncIterator()

        guard let outputPath = try await iterator.next() else {
            return false
        }

        guard outputPath != argsSeparator else {
            return false
        }

        // First argument is `wrapped_clang_pp`
        _ = try await iterator.next()

        let (args, hasDebugInfo, fortifySourceLevel) = try await processCCArgs(
            rawArguments: rawArguments
        )

        let content = args.map { $0 + "\n" }.joined()
        try Write()(content, to: URL(fileURLWithPath: String(outputPath)))

        buildSettings["C_PARAMS_FILE"] = #"""
"$(BAZEL_OUT)\#(outputPath.dropFirst(9))"
"""#

        if fortifySourceLevel > 0 {
            // ASAN doesn't work with `-D_FORTIFY_SOURCE=1`, so we need to only
            // include that when not building with ASAN
            buildSettings["ASAN_OTHER_CFLAGS__"] =
                #""$(ASAN_OTHER_CFLAGS__NO)""#
            buildSettings["ASAN_OTHER_CFLAGS__NO"] = #"""
"@$(DERIVED_FILE_DIR)/c.compile.params -D_FORTIFY_SOURCE=\#(fortifySourceLevel)"
"""#
            buildSettings["ASAN_OTHER_CFLAGS__YES"] =
                #""@$(DERIVED_FILE_DIR)/c.compile.params""#
            buildSettings["OTHER_CFLAGS"] =
                #""$(ASAN_OTHER_CFLAGS__$(CLANG_ADDRESS_SANITIZER))""#
        } else {
            buildSettings["OTHER_CFLAGS"] =
                #""@$(DERIVED_FILE_DIR)/c.compile.params""#
        }

        return hasDebugInfo
    }

    private static func processCxxArgs(
        rawArguments: AsyncThrowingStream<Substring, Error>,
        buildSettings: inout [String: String]
    ) async throws -> Bool {
        var iterator = rawArguments.makeAsyncIterator()

        guard let outputPath = try await iterator.next() else {
            return false
        }

        guard outputPath != argsSeparator else {
            return false
        }

        // First argument is `wrapped_clang_pp`
        _ = try await iterator.next()

        let (args, hasDebugInfo, fortifySourceLevel) = try await processCCArgs(
            rawArguments: rawArguments
        )

        let content = args.map { $0 + "\n" }.joined()
        try Write()(content, to: URL(fileURLWithPath: String(outputPath)))

        buildSettings["CXX_PARAMS_FILE"] = #"""
"$(BAZEL_OUT)\#(outputPath.dropFirst(9))"
"""#

        if fortifySourceLevel > 0 {
            // ASAN doesn't work with `-D_FORTIFY_SOURCE=1`, so we need to only
            // include that when not building with ASAN
            buildSettings["ASAN_OTHER_CPLUSPLUSFLAGS__"] =
                #""$(ASAN_OTHER_CPLUSPLUSFLAGS__NO)""#
            buildSettings["ASAN_OTHER_CPLUSPLUSFLAGS__NO"] = #"""
"@$(DERIVED_FILE_DIR)/cxx.compile.params \#
-D_FORTIFY_SOURCE=\#(fortifySourceLevel)"
"""#
            buildSettings["ASAN_OTHER_CPLUSPLUSFLAGS__YES"] =
                #""@$(DERIVED_FILE_DIR)/cxx.compile.params""#
            buildSettings["OTHER_CPLUSPLUSFLAGS"] =
                #""$(ASAN_OTHER_CPLUSPLUSFLAGS__$(CLANG_ADDRESS_SANITIZER))""#
        } else {
            buildSettings["OTHER_CPLUSPLUSFLAGS"] =
                #""@$(DERIVED_FILE_DIR)/cxx.compile.params""#
        }

        return hasDebugInfo
    }

    private static func processCCArgs(
        rawArguments: AsyncThrowingStream<Substring, Error>
    ) async throws -> (
        args: [Substring],
        hasDebugInfo: Bool,
        fortifySourceLevel: Int
    ) {
        var previousArg: Substring? = nil
        var skipNext = 0

        var args: [Substring] = [
            "-working-directory",
            "$(PROJECT_DIR)",
            "-ivfsoverlay",
            "$(OBJROOT)/bazel-out-overlay.yaml",
        ]

        var hasDebugInfo = false
        var fortifySourceLevel = 0
        for try await arg in rawArguments {
            guard arg != argsSeparator else {
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

            try processCCArg(
                arg,
                previousArg: previousArg,
                args: &args
            )
        }

        return (args, hasDebugInfo, fortifySourceLevel)
    }

    private static func processCCArg(
        _ arg: Substring,
        previousArg: Substring?,
        args: inout [Substring]
    ) throws {
        // `-ivfsoverlay` and `--config` don't apply `-working_directory=`, so
        // we need to prefix it ourselves
        for prefix in cNeedsAbsolutePathArgs {
            if arg.hasPrefix(prefix) {
                var path = arg.dropFirst(12)

                guard !path.isEmpty else {
                    args.append(arg)
                    return
                }

                if path.hasPrefix("=") {
                    path = path.dropFirst()
                }

                let absoluteArg: Substring = prefix + path.buildSettingPath()
                args.append(absoluteArg.quoteIfNeeded())
                return
            }
        }

        if let previousArg, cNeedsAbsolutePathArgs.contains(previousArg) {
            args.append(arg.buildSettingPath().quoteIfNeeded())
            return
        }

        args.append(arg.substituteBazelPlaceholders().quoteIfNeeded())
    }

    private static func parseArgs(
        rawArguments: Array<String>.SubSequence
    ) -> AsyncThrowingStream<Substring, Error> {
        return AsyncThrowingStream { continuation in
            let argsTask = Task {
                for arg in rawArguments {
                    guard !arg.starts(with: "@") else {
                        let path = String(arg.dropFirst())
                        for try await line in URL(fileURLWithPath: path).lines {
                            // Change params files from `shell` to `multiline`
                            // format
                            // https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
                            if line.hasPrefix("'") && line.hasSuffix("'") {
                                let startIndex = line
                                    .index(line.startIndex, offsetBy: 1)
                                let endIndex = line.index(before: line.endIndex)
                                continuation
                                    .yield(line[startIndex ..< endIndex])
                            } else {
                                continuation.yield(Substring(line))
                            }
                        }
                        continue
                    }
                    continuation.yield(Substring(arg))
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in
                argsTask.cancel()
            }
        }
    }
}

private let argsSeparator: Substring = "---"

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
    "-emit-objc-header-path": 1,
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
]

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

private let compilationModeArgs: [Substring: String] = [
    "-incremental": "singlefile",
    "-no-whole-module-optimization": "singlefile",
    "-whole-module-optimization": "wholemodule",
    "-wmo": "wholemodule",
]

private let clangSearchPathArgs: Set<Substring> = [
    "-F",
    "-I",
    "-iquote",
    "-isystem",
]

private let loadPluginsArgs: Set<Substring> = [
    "-load-plugin-executable",
    "-load-plugin-library",
]

private let cNeedsAbsolutePathArgs: Set<Substring> = [
    "--config",
    "-ivfsoverlay",
]

private let overlayArgs: Set<Substring> = [
    "-explicit-swift-module-map-file",
    "-vfsoverlay",
]

extension Substring {
    func buildSettingPath() -> Self {
        if self == "bazel-out" || starts(with: "bazel-out/") {
            // Dropping "bazel-out" prefix
            return "$(BAZEL_OUT)\(dropFirst(9))"
        }

        if self == "external" || starts(with: "external/") {
            // Dropping "external" prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(8))"
        }

        if self == ".." || starts(with: "../") {
            // Dropping ".." prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(2))"
        }

        if self == "." {
            // We need to use Bazel's execution root for ".", since includes can
            // reference things like "external/" and "bazel-out"
            return "$(PROJECT_DIR)"
        }

        let substituted = substituteBazelPlaceholders()

        if substituted.hasPrefix("/") {
            return substituted
        }

        return "$(SRCROOT)/\(substituted)"
    }

    func substituteBazelPlaceholders() -> Self {
        return
            // Use Xcode set `DEVELOPER_DIR`
            replacing(
                "__BAZEL_XCODE_DEVELOPER_DIR__",
                with: "$(DEVELOPER_DIR)"
            )
            // Use Xcode set `SDKROOT`
            .replacing("__BAZEL_XCODE_SDKROOT__", with: "$(SDKROOT)")
    }

    func quoteIfNeeded() -> Self {
        // Quote the arg if it contains spaces
        guard !contains(" ") else {
            return "'\(self)'"
        }
        return self
    }
}

extension String {
    func buildSettingPath(
        useXcodeBuildDir: Bool = false
    ) -> Self {
        if self == "bazel-out" || starts(with: "bazel-out/") {
            // Dropping "bazel-out" prefix
            if useXcodeBuildDir {
                return "$(BUILD_DIR)\(dropFirst(9))"
            } else {
                return "$(BAZEL_OUT)\(dropFirst(9))"
            }
        }

        if self == "external" || starts(with: "external/") {
            // Dropping "external" prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(8))"
        }

        if self == ".." || starts(with: "../") {
            // Dropping ".." prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(2))"
        }

        if self == "." {
            // We need to use Bazel's execution root for ".", since includes can
            // reference things like "external/" and "bazel-out"
            return "$(PROJECT_DIR)"
        }

        let substituted = substituteBazelPlaceholders()

        if substituted.hasPrefix("/") {
            return substituted
        }

        return "$(SRCROOT)/\(substituted)"
    }

    func substituteBazelPlaceholders() -> Self {
        return
            // Use Xcode set `DEVELOPER_DIR`
            replacing(
                "__BAZEL_XCODE_DEVELOPER_DIR__",
                with: "$(DEVELOPER_DIR)"
            )
            // Use Xcode set `SDKROOT`
            .replacing("__BAZEL_XCODE_SDKROOT__", with: "$(SDKROOT)")
    }

    func quoteIfNeeded() -> Self {
        // Quote the arg if it contains spaces
        guard !contains(" ") else {
            return "'\(self)'"
        }
        return self
    }
}

extension Array<String>.SubSequence {
    mutating func popArgument(_ name: String) throws -> String {
        guard let arg = popFirst() else {
            throw PreconditionError(message: "Missing <\(name)>")
        }
        return arg
    }
}
