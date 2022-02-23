import Foundation

/// An `Error` that represents a programming error.
struct PreconditionError: Error {
    let message: String
}

// MARK: LocalizedError

extension PreconditionError: LocalizedError {
    var errorDescription: String? {
        return """
Internal precondition failure:
\(message)
Please file a bug report at \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
"""
    }
}

