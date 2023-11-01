extension Generator {
    struct ProcessSwiftFrontendArg {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Processes a single Swift frontend (`-Xfrontend`) argument.
        func callAsFunction(
            _ arg: String,
            previousFrontendArg: String?,
            args: inout [String]
        ) throws {
            try callable(
                /*arg:*/ arg,
                /*previousFrontendArg:*/ previousFrontendArg,
                /*args:*/ &args
            )
        }
    }
}

// MARK: - ProcessSwiftFrontendArg.Callable

extension Generator.ProcessSwiftFrontendArg {
    typealias Callable = (
        _ arg: String,
        _ previousFrontendArg: String?,
        _ args: inout [String]
    ) throws -> Void

    static func defaultCallable(
        _ arg: String,
        previousFrontendArg: String?,
        args: inout [String]
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

        if arg.hasPrefix("-vfsoverlay") {
            var path = arg.dropFirst(11)

            guard !path.isEmpty else {
                args.append(arg)
                return
            }

            if path.hasPrefix("=") {
                path = path.dropFirst()
            }

            let absoluteArg: Substring =
                "-vfsoverlay" + path.buildSettingPath()
            args.append(absoluteArg.quoteIfNeeded())
            return
        }

        args.append(arg.substituteBazelPlaceholders().quoteIfNeeded())
    }
}

private let loadPluginsArgs: Set<String> = [
    "-load-plugin-executable",
    "-load-plugin-library",
]

private let overlayArgs: Set<String> = [
    "-explicit-swift-module-map-file",
    "-vfsoverlay",
]
