enum BuildMode: String {
    case xcode
    case bazel
}

extension BuildMode {
    var allowsGeneratedInfoPlists: Bool {
        switch self {
        case .xcode: return true
        case .bazel: return false
        }
    }

    var buildOutputGroupPrefix: String {
        switch self {
        case .xcode:
            // Generated input files output groups
            return "g"
        case .bazel:
            // Output files output groups
            return "b"
        }
    }

    /// `true` if when building with Bazel we use run scripts.
    ///
    /// Building with Bazel via a proxy doesn't use run scripts.
    var usesBazelModeBuildScripts: Bool {
        switch self {
        case .xcode: return false
        case .bazel: return true
        }
    }

    var usesBazelEnvironmentVariables: Bool {
        switch self {
        case .xcode: return false
        case .bazel: return true
        }
    }
}
