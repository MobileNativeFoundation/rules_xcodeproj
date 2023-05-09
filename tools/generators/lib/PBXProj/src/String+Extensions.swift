import Foundation

extension String {
    private static var invalidCharacters: CharacterSet = {
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

    private static var specialCheckCharacters = CharacterSet(charactersIn: "_/")

    /// Copied from https://github.com/tuist/XcodeProj/blob/f570155209af12643309ac4e758b875c63dcbf50/Sources/XcodeProj/Utils/CommentedString.swift#L21-L69
    public var pbxProjEscaped: String {
        guard !isEmpty else {
            return "\"\""
        }

        if rangeOfCharacter(from: Self.invalidCharacters) == nil {
            if rangeOfCharacter(from: Self.specialCheckCharacters) == nil {
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

    public var quoted: String {
        return "\"\(self)\""
    }
}
