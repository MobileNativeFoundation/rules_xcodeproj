import XCTest

@testable import generator

/// A `TextOutputStream` that writes to a string.
final class StringOutputStream: TextOutputStream {
    private(set) var output = ""

    func write(_ string: String) {
        output += string
    }
}

final class DefaultLoggerTests: XCTestCase {
    func test_logDebug() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout)
        logger.logDebug("this is a debug message")
        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "DEBUG: this is a debug message\n")
    }

    func test_logInfo() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout)
        logger.logInfo("this is an info message")
        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "INFO: this is an info message\n")
    }

    func test_logWarning() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout)
        logger.logWarning("this is a warning message")
        XCTAssertEqual(stderr.output, "WARNING: this is a warning message\n")
        XCTAssertEqual(stdout.output, "")
    }

    func test_logError() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout)
        logger.logError("this is an error message")
        XCTAssertEqual(stderr.output, "ERROR: this is an error message\n")
        XCTAssertEqual(stdout.output, "")
    }
}
