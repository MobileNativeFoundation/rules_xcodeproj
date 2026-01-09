import ArgumentParser

/// How automatically generated schemes should be generated.
enum AutogenerationMode: String, ExpressibleByArgument {
    /// If there are no custom schemes, then `.all`, otherwise, `.none`.
    case auto

    /// Schemes for every target should be automatically generated.
    case all

    /// Schemes for every top-level target should be automatically generated.
    ///
    /// Top-level targets are bundled or executable targets (e.g. apps,
    /// extensions, tests, and command-line tools). Non-top-level targets (e.g.
    /// libraries and frameworks) are excluded.
    case topLevelOnly = "top_level_only"

    /// No automatically generated schemes should be generated.
    case none
}
