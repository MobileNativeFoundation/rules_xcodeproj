import Foundation

/// An `Error` that represents a user error.
struct UsageError: Error {
    let message: String
}

// MARK: LocalizedError

extension UsageError: LocalizedError {
    var errorDescription: String? { message }
}

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

