import Foundation
import GeneratorCommon

extension ElementCreator {
    #Injectable(asStatic: true) {
        /// If `path` is for a symlink, it's recursively resolved to an absolute
        /// path and returned. Otherwise returns `nil`.
        func resolveSymlink(_ path: String) -> String? {
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
                        // This can happen if a symlink points to `/tmp` as it
                        // will resolve to `/private/tmp` and then
                        // `.standardizingPath` will change it back to `/tmp`.
                        // We need to return here otherwise it will loop
                        // forever.
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
}
