import Foundation

extension String {
    private var isExternalBazelPath: Bool {
        return hasPrefix("external/") || self == "external"
    }

    private var isGeneratedBazelPath: Bool {
        return hasPrefix("bazel-out/") || self == "bazel-out"
    }

    /// Converts a Bazel based path to one suitable for use in Xcode build
    /// settings. This uses `$(BUILD_DIR)`, `$(BAZEL_EXTERNAL)`, and
    /// `$(SRCROOT)` for relative paths.
    public var derivedDataBasedBuildSettingPath: String {
        if isExternalBazelPath {
            // Removing "external" prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(8))"
        } else if isGeneratedBazelPath {
            return "$(BUILD_DIR)/\(self)"
        } else if hasPrefix("/") {
            // Absolute path
            return self
        } else {
            return "$(SRCROOT)/\(self)"
        }
    }

    /// Converts a Bazel based path to one suitable for use in Xcode build
    /// settings. This uses `$(BAZEL_OUT)`, `$(BAZEL_EXTERNAL)`, and
    /// `$(SRCROOT)` for relative paths.
    public var executionRootBasedBuildSettingPath: String {
        if isExternalBazelPath {
            // Removing "external" prefix
            return "$(BAZEL_EXTERNAL)\(dropFirst(8))"
        } else if isGeneratedBazelPath {
            // Removing "bazel-out" prefix
            return "$(BAZEL_OUT)\(dropFirst(9))"
        } else if hasPrefix("/") {
            // Absolute path
            return self
        } else {
            return "$(SRCROOT)/\(self)"
        }
    }
}


private let invalidCharacters: CharacterSet = {
    var invalidSet = CharacterSet(charactersIn: "_$")
    invalidSet.insert(UnicodeScalar("/"))
    invalidSet.insert(UnicodeScalar("."))
    invalidSet.insert(
        charactersIn: UnicodeScalar("0") ... UnicodeScalar("9")
    )
    invalidSet.insert(
        charactersIn: UnicodeScalar("A") ... UnicodeScalar("Z")
    )
    invalidSet.insert(
        charactersIn: UnicodeScalar("a") ... UnicodeScalar("z")
    )
    invalidSet.invert()
    return invalidSet
}()

private let specialCheckCharacters = CharacterSet(charactersIn: "_/")

extension StringProtocol {
    /// Copied from https://github.com/tuist/XcodeProj/blob/f570155209af12643309ac4e758b875c63dcbf50/Sources/XcodeProj/Utils/CommentedString.swift#L21-L69
    public var pbxProjEscaped: Self {
        guard !isEmpty else {
            return "\"\""
        }

        if rangeOfCharacter(from: invalidCharacters) == nil {
            if rangeOfCharacter(from: specialCheckCharacters) == nil {
                return self
            } else if !contains("//") && !contains("___") {
                return self
            }
        }

        let escaped = reduce(into: "") { escaped, character in
            // As an optimization, only look at the first scalar. This means
            // we're doing a numeric comparison instead of comparing
            // arbitrary-length characters. This is safe because all our cases
            // are a single scalar.
            switch character.unicodeScalars.first {
            case "\\":
                escaped.append("\\\\")
            case "\"":
                escaped.append("\\\"")
            case "\t":
                escaped.append("\\t")
            case "\n":
                escaped.append("\\n")
            default:
                escaped.append(character)
            }
        }

        return "\"\(escaped)\""
    }

    public var quoted: Self {
        return "\"\(self)\""
    }
}
