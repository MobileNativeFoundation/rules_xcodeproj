public enum Runnable {
    case plain(buildableReference: BuildableReference)
    case hosted(
        buildableReference: BuildableReference,
        hostBuildableReference: BuildableReference,
        debuggingMode: Int,
        remoteBundleIdentifier: String
    )
}
