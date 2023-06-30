public enum BuildPhase {
    case bazelIntegration
    case createCompileDependencies
    case createLinkDependencies
    case headers
    case sources
    case copySwiftGeneratedHeader
    case resources
    case embedFrameworks
    case embedWatchContent
    case embedAppExtensions
    case embedAppClips

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
        case .resources: return "Resources"
        case .embedFrameworks: return "Embed Frameworks"
        case .embedWatchContent: return "Embed Watch Content"
        case .embedAppExtensions: return "Embed App Extensions"
        case .embedAppClips: return "Embed App Clips"
        }
    }
}
