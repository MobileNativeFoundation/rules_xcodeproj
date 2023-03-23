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

enum TerminalColor: Int {
    case red = 31
    case green = 32
    case yellow = 33
    case magenta = 35

    func colorize(_ input: String) -> String {
        let bold: Bool
        switch self {
        case .red:
            bold = true
        case .green, .yellow, .magenta:
            bold = false
        }
        return "\u{001B}[\(self.rawValue)\(bold ? ";1" : "")m\(input)\u{001B}[0m"
    }
}

/// The logger that is used when not running tests.
final class DefaultLogger<E: TextOutputStream, O: TextOutputStream>: Logger {
    private var standardError: E
    private var standardOutput: O
    private var colorize: Bool

    func enableColors() {
        self.colorize = true
    }

    init(standardError: E, standardOutput: O, colorize: Bool) {
        self.standardError = standardError
        self.standardOutput = standardOutput
        self.colorize = colorize
    }

    func format(color: TerminalColor, prefix: String, message: String) -> String {
        if self.colorize {
            return "\(color.colorize("\(prefix):")) \(message)"
        } else {
            return "\(prefix): \(message)"
        }
    }

    func logDebug(_ message: String) {
        print(
            self.format(color: .yellow, prefix: "DEBUG", message: message),
            to: &self.standardOutput
        )
    }

    func logInfo(_ message: String) {
        print(
            self.format(color: .green, prefix: "INFO", message: message),
            to: &self.standardOutput
        )
    }

    func logWarning(_ message: String) {
        print(
            self.format(color: .magenta, prefix: "WARNING", message: message),
            to: &self.standardError
        )
    }

    func logError(_ message: String) {
        print(
            self.format(color: .red, prefix: "ERROR", message: message),
            to: &self.standardError
        )
    }
}
