import Darwin

/// Provides the capability to write log messages.
protocol Logger {
    func logDebug(_ message: @autoclosure () -> String)
    func logInfo(_ message: @autoclosure () -> String)
    func logWarning(_ message: @autoclosure () -> String)
    func logError(_ message: @autoclosure () -> String)
}

/// A `TextOutputStream` that writes to standard error.
final class StderrOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

/// A `TextOutputStream` that writes to standard out.
final class StdoutOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stdout)
    }
}

/// The logger that is used when not running tests.
final class DefaultLogger<E: TextOutputStream, O: TextOutputStream>: Logger {
    private var standardError: E
    private var standardOutput: O

    init(standardError: E, standardOutput: O) {
        self.standardError = standardError
        self.standardOutput = standardOutput
    }

    func logDebug(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("DEBUG: \(message())", to: &self.standardOutput)
    }

    func logInfo(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("INFO: \(message())", to: &self.standardOutput)
    }

    func logWarning(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("WARNING: \(message())", to: &self.standardError)
    }

    func logError(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        print("ERROR: \(message())", to: &self.standardError)
    }
}
