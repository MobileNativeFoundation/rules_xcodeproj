/// Values that can be set on `PBXFileReference.sourceTree` and the same
/// property on similar elements (e.g. `PBXGroup`).
///
/// - Note: `.rawValue` is already PBXProj escaped, so don't call
///   `.pbxProjEscaped` on them.
public enum SourceTree: String {
    case absolute = "\"<absolute>\""
    case group = "\"<group>\""
    case sourceRoot = "SOURCE_ROOT"
}
