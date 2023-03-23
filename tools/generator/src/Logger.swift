import Darwin

/// Provides the capability to write log messages.
protocol Logger {
    func logDebug(_ message: String)
    func logInfo(_ message: String)
    func logWarning(_ message: String)
    func logError(_ message: String)
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

    func logDebug(_ message: String) {
        print("DEBUG: \(message())", to: &self.standardOutput)
    }

    func logInfo(_ message: String) {
        print("INFO: \(message())".blue, to: &self.standardOutput)
    }

    func logWarning(_ message: String) {
        print("WARNING: \(message())".yellow, to: &self.standardError)
    }

    func logError(_ message: String) {
        print("ERROR: \(message())".red, to: &self.standardError)
    }
}

private extension String {
    var blue: String   { "\u{001B}[34m\(self)\u{001B}[0m" }
    var yellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }
    var red: String    { "\u{001B}[31m\(self)\u{001B}[0m" }
}
