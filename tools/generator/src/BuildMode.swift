enum BuildMode: String {
    case xcode
    case bazel
}

extension BuildMode {
    var requiresLLDBInit: Bool {
        switch self {
        case .xcode: return false
        case .bazel: return true
        }
    }
}
