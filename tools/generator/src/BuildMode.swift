enum BuildMode: String {
    case xcode
    case bazel
}

extension BuildMode {
    /// `true` if when building with Bazel we use run scripts.
    ///
    /// Building with Bazel via a proxy doesn't use run scripts.
    var usesBazelModeBuildScripts: Bool {
        switch self {
        case .xcode: return false
        case .bazel: return true
        }
    }

    var requiresLLDBInit: Bool {
        switch self {
        case .xcode: return false
        case .bazel: return true
        }
    }
}
