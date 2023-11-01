import OrderedCollections

extension Generator {
    struct ProcessSwiftArg {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Processes a single Swift argument.
        func callAsFunction(
            _ arg: String,
            previousArg: String?,
            previousFrontendArg: String?,
            args: inout [String],
            buildSettings: inout [(key: String, value: String)],
            frameworkIncludes: inout OrderedSet<String>,
            includeSelfSwiftDebugSettings: Bool,
            swiftIncludes: inout OrderedSet<String>
        ) throws {
            try callable(
                /*arg:*/ arg,
                /*previousArg:*/ previousArg,
                /*previousFrontendArg:*/ previousFrontendArg,
                /*args:*/ &args,
                /*buildSettings:*/ &buildSettings,
                /*frameworkIncludes:*/ &frameworkIncludes,
                /*includeSelfSwiftDebugSettings:*/
                    includeSelfSwiftDebugSettings,
                /*swiftIncludes:*/ &swiftIncludes
            )
        }
    }
}

// MARK: - ProcessSwiftArg.Callable

extension Generator.ProcessSwiftArg {
    typealias Callable = (
        _ arg: String,
        _ previousArg: String?,
        _ previousFrontendArg: String?,
        _ args: inout [String],
        _ buildSettings: inout [(key: String, value: String)],
        _ frameworkIncludes: inout OrderedSet<String>,
        _ includeSelfSwiftDebugSettings: Bool,
        _ swiftIncludes: inout OrderedSet<String>
    ) throws -> Void

    static func defaultCallable(
        _ arg: String,
        previousArg: String?,
        previousFrontendArg: String?,
        args: inout [String],
        buildSettings: inout [(key: String, value: String)],
        frameworkIncludes: inout OrderedSet<String>,
        includeSelfSwiftDebugSettings: Bool,
        swiftIncludes: inout OrderedSet<String>
    ) throws {
        let appendIncludes:
            (_ set: inout OrderedSet<String>, _ path: String) -> Void
        if includeSelfSwiftDebugSettings {
            appendIncludes = { set, path in
                set.append(path.escapingForDebugSettings())
            }
        } else {
            appendIncludes = { _, _ in }
        }

        if let compilationMode = compilationModeArgs[arg] {
            buildSettings.append(("SWIFT_COMPILATION_MODE", compilationMode))
            return
        }

        if previousArg == "-swift-version" {
            if arg != "5.0" {
                buildSettings.append(("SWIFT_VERSION", String(arg)))
            }
            return
        }

        if arg.hasPrefix("-I") {
            let path = arg.dropFirst(2)
            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            let absolutePath = path.buildSettingPath()
            let absoluteArg = "-I" + absolutePath
            args.append(absoluteArg.quoteIfNeeded())
            appendIncludes(&swiftIncludes, absolutePath)
            return
        }

        if previousArg == "-I" {
            let absolutePath = arg.buildSettingPath()
            args.append(absolutePath.quoteIfNeeded())
            appendIncludes(&swiftIncludes, absolutePath)
            return
        }

        if previousArg == "-F" {
            let absolutePath = arg.buildSettingPath()
            args.append(absolutePath.quoteIfNeeded())
            appendIncludes(&frameworkIncludes, absolutePath)
            return
        }

        if arg.hasPrefix("-F") {
            let path = arg.dropFirst(2)

            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            let absolutePath = path.buildSettingPath()
            let absoluteArg = "-F" + absolutePath
            args.append(absoluteArg.quoteIfNeeded())
            appendIncludes(&frameworkIncludes, absolutePath)
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

            let absoluteArg = "-vfsoverlay" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        if previousArg == "-vfsoverlay" {
            args.append(arg.buildSettingPath().quoteIfNeeded())
            return
        }

        args.append(arg.substituteBazelPlaceholders().quoteIfNeeded())
    }
}

private let compilationModeArgs: [String: String] = [
    "-incremental": "singlefile",
    "-no-whole-module-optimization": "singlefile",
    "-whole-module-optimization": "wholemodule",
    "-wmo": "wholemodule",
]
