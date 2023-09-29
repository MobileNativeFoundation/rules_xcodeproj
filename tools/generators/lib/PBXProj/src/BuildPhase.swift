public enum BuildPhase {
    case bazelIntegration
    case createCompileDependencies
    case createLinkDependencies
    case headers
    case sources
    case copySwiftGeneratedHeader
    case embedAppExtensions

    public var name: String {
        switch self {
        case .bazelIntegration: return """
Copy Bazel Outputs / Generate Bazel Dependencies (Index Build)
"""
        case .createCompileDependencies: return "Create Compile Dependencies"
        case .createLinkDependencies: return "Create Link Dependencies"
        case .headers: return "Headers"
        case .sources: return "Sources"
        case .copySwiftGeneratedHeader: return "Copy Swift Generated Header"
        case .embedAppExtensions: return "Embed App Extensions"
        }
    }
}
