import GeneratorCommon
import XcodeProj

extension BuildMode {
    var launchEnvironmentVariables: [XCScheme.EnvironmentVariable] {
        switch self {
        case .xcode: return []
        case .bazel: return .bazelLaunchEnvironmentVariables
        }
    }
}
