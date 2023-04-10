import PathKit

enum FilePathResolver {
    static func resolveRelativeToExecutionRoot(_ filePath: FilePath) -> String {
        let path: String
        switch filePath.type {
        case .generated:
            path = "bazel-out/\(filePath.path)"
        case .external:
            path = "external/\(filePath.path)"
        case .project:
            // We could check for `"."`, but this is only called on actual paths
            path = filePath.path.string
        }

        return path
    }

    static func resolveExternal(_ path: Path) -> String {
        return "$(BAZEL_EXTERNAL)/\(path)"
    }

    static func resolveGenerated(_ path: Path) -> String {
        // Technically we should handle when `path` == `.`, but we never
        // reference anything that can be just `bazel-out` in the generator
        // anymore
        return "$(BAZEL_OUT)/\(path)"
    }
}
