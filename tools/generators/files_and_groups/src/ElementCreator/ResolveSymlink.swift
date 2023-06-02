import Foundation

extension ElementCreator {
    struct ResolveSymlink {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// If `path` is for a symlink, it's recursively resolved to an absolute
        /// path and returned. Otherwise returns `nil`.
        func callAsFunction(_ path: String) -> String? {
            return callable(/*path:*/ path)
        }
    }
}

// MARK: - ResolveSymlink.Callable

extension ElementCreator.ResolveSymlink {
    typealias Callable = (_ path: String) -> String?

    /// If `path` is for a symlink, it's recursively resolved to an absolute
    /// path and returned. Otherwise returns `nil`.
    static func defaultCallable(path: String) -> String? {
        let fileManager = FileManager.default

        var resolvedASymlink = false
        var pathToResolve = path
        while let symlinkDest = try? fileManager
            .destinationOfSymbolicLink(atPath: pathToResolve)
        {
            resolvedASymlink = true
            if symlinkDest.starts(with: "/") {
                pathToResolve = symlinkDest
            } else {
                let newPathToResolve = NSString(
                    string: "\(pathToResolve)/../\(symlinkDest)"
                ).standardizingPath

                guard newPathToResolve != pathToResolve else {
                    // This can happen if a symlink points to `/tmp` as it will
                    // resolve to `/private/tmp` and then `.standardizingPath`
                    // will change it back to `/tmp`. We need to return here
                    // otherwise it will loop forever.
                    return pathToResolve
                }

                pathToResolve = newPathToResolve
            }
        }

        guard resolvedASymlink else {
            return nil
        }

        return pathToResolve
    }
}
