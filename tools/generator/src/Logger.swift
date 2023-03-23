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
final class DefaultLogger: Logger {
    private var standardError: any TextOutputStream
    private var standardOutput: any TextOutputStream

    init(standardError: TextOutputStream = StderrOutputStream(), standardOutput: TextOutputStream = StdoutOutputStream()) {
        self.standardError = standardError
        self.standardOutput = standardOutput
    }

    func logDebug(_ message: @autoclosure () -> String) {
        print("DEBUG: \(message())", to: &self.standardOutput)
    }

    func logInfo(_ message: @autoclosure () -> String) {
        print("INFO: \(message())".blue, to: &self.standardOutput)
    }

    func logWarning(_ message: @autoclosure () -> String) {
        print("WARNING: \(message())".yellow, to: &self.standardError)
    }

    func logError(_ message: @autoclosure () -> String) {
        print("ERROR: \(message())".red, to: &self.standardError)
    }
}

private extension String {
    var blue: String   { "\u{001B}[34m\(self)\u{001B}[0m" }
    var yellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }
    var red: String    { "\u{001B}[31m\(self)\u{001B}[0m" }
}
