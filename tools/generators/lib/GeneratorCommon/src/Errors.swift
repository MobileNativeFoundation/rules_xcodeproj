import Foundation

/// An `Error` that represents a user error.
public struct UsageError: Error {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

/// An `Error` that represents a programming error.
public struct PreconditionError: Error {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

// MARK: LocalizedError

extension UsageError: LocalizedError {
    public var errorDescription: String? { message }
}

extension PreconditionError: LocalizedError {
    public var errorDescription: String? {
        return """
Internal precondition failure:
\(message)
Please file a bug report at \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
"""
    }
}
