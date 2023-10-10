import ArgumentParser

public enum BuildMode: String, ExpressibleByArgument {
    case xcode
    case bazel
}

extension BuildMode {
    public var allowsGeneratedInfoPlists: Bool {
        switch self {
        case .xcode: return true
        case .bazel: return false
        }
    }

    /// `true` if when building with Bazel we use run scripts.
    ///
    /// Building with Bazel via a proxy doesn't use run scripts.
    public var usesBazelModeBuildScripts: Bool {
        switch self {
        case .xcode: return false
        case .bazel: return true
        }
    }
}
