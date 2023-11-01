extension Generator {
    struct ProcessCcArg {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Processes a single C/C++/Objective-C argument.
        func callAsFunction(
            _ arg: String,
            previousArg: String?,
            args: inout [String]
        ) throws {
            try callable(
                /*arg:*/ arg,
                /*previousArg:*/ previousArg,
                /*args:*/ &args
            )
        }
    }
}

// MARK: - ProcessCcArg.Callable

extension Generator.ProcessCcArg {
    typealias Callable = (
        _ arg: String,
        _ previousArg: String?,
        _ args: inout [String]
    ) throws -> Void

    static func defaultCallable(
        _ arg: String,
        previousArg: String?,
        args: inout [String]
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

                let absoluteArg = prefix + path.buildSettingPath()
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
}

private let cNeedsAbsolutePathArgs: Set<String> = [
    "--config",
    "-ivfsoverlay",
]
