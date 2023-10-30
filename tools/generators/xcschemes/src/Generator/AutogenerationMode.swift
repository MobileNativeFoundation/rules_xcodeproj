import ArgumentParser

/// How automatically generated schemes should be generated.
enum AutogenerationMode: String, ExpressibleByArgument {
    /// If there are no custom schemes, then `.all`, otherwise, `.none`.
    case auto

    /// Schemes for every target should be automatically generated.
    case all

    /// No automatically generated schemes should be generated.
    case none
}
