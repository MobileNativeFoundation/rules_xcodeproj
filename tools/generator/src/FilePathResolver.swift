import PathKit

enum FilePathResolver {
    static func resolve(_ filePath: FilePath) -> String {
        let path: String
        switch filePath.type {
        case .project:
            guard filePath.path.normalize() != "." else {
                // We need to use Bazel's execution root for ".", since includes
                // can reference things like "external/" and "bazel-out"
                return "$(PROJECT_DIR)"
            }

            path = "$(SRCROOT)/\(filePath.path)"
        case .external:
            path = Self.resolveExternal(filePath.path)
        case .generated:
            path = Self.resolveGenerated(filePath.path)
        case .internal:
            path = Self.resolveInternal(filePath.path)
        }

        return path
    }

    static func resolveExternal(_ path: Path) -> String {
        return "$(BAZEL_EXTERNAL)/\(path)"
    }

    static func resolveGenerated(_ path: Path) -> String {
        return "$(BAZEL_OUT)/\(path)"
    }

    static func resolveInternal(_ path: Path) -> String {
        return "$(INTERNAL_DIR)/\(path)"
    }
}
