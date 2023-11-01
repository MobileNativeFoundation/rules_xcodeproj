extension Generator {
    struct ProcessSwiftClangArg {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Processes a single Swift clang (`-Xcc`) argument.
        func callAsFunction(
            _ arg: String,
            previousClangArg: String?,
            args: inout [String],
            clangArgs: inout [String],
            includeSelfSwiftDebugSettings: Bool,
            onceClangArgs: inout Set<String>
        ) throws {
            try callable(
                /*arg:*/ arg,
                /*previousClangArg:*/ previousClangArg,
                /*args:*/ &args,
                /*clangArgs:*/ &clangArgs,
                /*includeSelfSwiftDebugSettings:*/
                    includeSelfSwiftDebugSettings,
                /*onceClangArgs:*/ &onceClangArgs
            )
        }
    }
}

// MARK: - ProcessSwiftClangArg.Callable

extension Generator.ProcessSwiftClangArg {
    typealias Callable = (
        _ arg: String,
        _ previousClangArg: String?,
        _ args: inout [String],
        _ clangArgs: inout [String],
        _ includeSelfSwiftDebugSettings: Bool,
        _ onceClangArgs: inout Set<String>
    ) throws -> Void

    static func defaultCallable(
        _ arg: String,
        previousClangArg: String?,
        args: inout [String],
        clangArgs: inout [String],
        includeSelfSwiftDebugSettings: Bool,
        onceClangArgs: inout Set<String>
    ) throws {
        func appendClangArg(
            _ clangArg: String,
            disallowMultiples: Bool = true
        ) {
            guard includeSelfSwiftDebugSettings else {
                return
            }
            if disallowMultiples {
                guard !onceClangArgs.contains(clangArg) else {
                    return
                }
                onceClangArgs.insert(clangArg)
            }
            clangArgs.append(clangArg)
        }

        if arg.hasPrefix("-fmodule-map-file=") {
            let path = arg.dropFirst(18)
            let absoluteArg: Substring =
                "-fmodule-map-file=" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            appendClangArg(absoluteArg.escapingForDebugSettings())
            return
        }

        if arg.hasPrefix("-D") {
            let absoluteArg = arg.substituteBazelPlaceholders()
            args.append(absoluteArg.quoteIfNeeded())
            appendClangArg(absoluteArg.escapingForDebugSettings())
            return
        }

        for (searchArg, disallowMultiples) in clangSearchPathArgs {
            if arg.hasPrefix(searchArg) {
                let path = arg.dropFirst(searchArg.count)

                guard !path.isEmpty else {
                    args.append(arg)
                    return
                }

                args.append(searchArg)
                args.append("-Xcc")

                let absoluteArg = path.buildSettingPath()
                args.append(absoluteArg.quoteIfNeeded())
                appendClangArg(
                    (searchArg + absoluteArg).escapingForDebugSettings(),
                    disallowMultiples: disallowMultiples
                )
                return
            }
        }

        if let previousClangArg,
           let disallowMultiples = clangSearchPathArgs[previousClangArg]
        {
            let absoluteArg = arg.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            appendClangArg(
                (previousClangArg + absoluteArg).escapingForDebugSettings(),
                disallowMultiples: disallowMultiples
            )
        }

        // `-ivfsoverlay` doesn't apply `-working_directory=`, so we need to
        // prefix it ourselves
        if previousClangArg == "-ivfsoverlay" {
            let absolutePath = arg.buildSettingPath()
            args.append(absolutePath.quoteIfNeeded())
            appendClangArg(
                ("-ivfsoverlay" + absolutePath).escapingForDebugSettings()
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
            appendClangArg(absoluteArg.escapingForDebugSettings())
            return
        }

        let absoluteArg = arg.substituteBazelPlaceholders()
        args.append(absoluteArg.quoteIfNeeded())
        appendClangArg(
            absoluteArg.escapingForDebugSettings(),
            disallowMultiples: false
        )
    }
}

// Maps arg -> multiples not allowed in clangArgs
private let clangSearchPathArgs: [String: Bool] = [
    "-F": true,
    "-I": true,
    "-iquote": false,
    "-isystem": false,
]
