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
private final class StderrOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

/// A `TextOutputStream` that writes to a string.
final class StringOutputStream: TextOutputStream {
    private(set) var output = ""

    func write(_ string: String) {
        output += string
    }
}

/// The logger that is used when not running tests.
final class DefaultLogger: Logger {
    private var standardError = StderrOutputStream()
    private var testOutputStream: StringOutputStream?

    func overrideOutputStreamForTests(_ outputStream: StringOutputStream) {
        self.testOutputStream = outputStream
    }

    func logDebug(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        self.loggerPrint("DEBUG: \(message())", useStderr: false)
    }

    func logInfo(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        self.loggerPrint("INFO: \(message())", useStderr: false)
    }

    func logWarning(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        self.loggerPrint("WARNING: \(message())", useStderr: true)
    }

    func logError(_ message: @autoclosure () -> String) {
        // TODO: Colorize
        self.loggerPrint("ERROR: \(message())", useStderr: true)
    }

    private func loggerPrint(_ message: String, useStderr: Bool) {
        if var testOutputStream = self.testOutputStream {
            print(message, to: &testOutputStream)
        } else if useStderr {
            print(message, to: &standardError)
        } else {
            print(message)
        }
    }
}
