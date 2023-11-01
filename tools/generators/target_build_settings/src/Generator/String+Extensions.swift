extension StringProtocol {
    func buildSettingPath() -> String {
        if self == "bazel-out" || hasPrefix("bazel-out/") {
            // Dropping "bazel-out" prefix
            return "$(BAZEL_OUT)\(dropFirst(9))"
        }

        if self == "external" || hasPrefix("external/") {
            // Dropping "external" prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(8))"
        }

        if self == ".." || hasPrefix("../") {
            // Dropping ".." prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(2))"
        }

        if self == "." {
            // We need to use Bazel's execution root for ".", since includes can
            // reference things like "external/" and "bazel-out"
            return "$(PROJECT_DIR)"
        }

        let substituted = substituteBazelPlaceholders()

        if substituted.hasPrefix("/") || substituted.hasPrefix("$(") {
            return substituted
        }

        return "$(SRCROOT)/\(substituted)"
    }

    func escapingForDebugSettings() -> String {
        return replacingOccurrences(of: " ", with: #"\ "#)
            .replacingOccurrences(of: #"""#, with: #"\""#)
            // These nulls will become newlines with `.nullsToNewlines` in
            // `pbxnativetargets`. We need to escape them in order to be
            // able to split on newlines.
            .replacingOccurrences(of: "\n", with: "\0")
    }

    // FIXME: Use `escapingForDebugSettings` instead?
    func quoteIfNeeded() -> String {
        // Quote the arg if it contains spaces
        guard !contains(" ") else {
            return "'\(self)'"
        }
        return String(self)
    }

    func substituteBazelPlaceholders() -> String {
        return
            // Use Xcode set `DEVELOPER_DIR`
            replacingOccurrences(
                of: "__BAZEL_XCODE_DEVELOPER_DIR__",
                with: "$(DEVELOPER_DIR)"
            )
            // Use Xcode set `SDKROOT`
            .replacingOccurrences(
                of: "__BAZEL_XCODE_SDKROOT__",
                with: "$(SDKROOT)"
            )
    }
}
