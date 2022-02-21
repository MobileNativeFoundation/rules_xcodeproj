import func Darwin.fputs
import var Darwin.stderr

/// Provides the capability to write log messages.
protocol Logger {
    func logDebug(_ message: @autoclosure () -> String)
    func logInfo(_ message: @autoclosure () -> String)
    func logWarning(_ message: @autoclosure () -> String)
    func logError(_ message: @autoclosure () -> String)
}

/// A `TextOutputStream` that writes to standard error.
private class StderrOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

/// The logger that is used when not running tests.
class DefaultLogger: Logger {
    private var standardError = StderrOutputStream()

    func logDebug(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("DEBUG: \(message())")
    }

    func logInfo(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("INFO: \(message())")
    }

    func logWarning(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("WARNING: \(message())", to: &standardError)
    }

    func logError(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("ERROR: \(message())", to: &standardError)
    }
}
