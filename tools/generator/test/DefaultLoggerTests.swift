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
    // MARK: - With Colors

    func test_logDebug_With_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: true)
        logger.logDebug("this is a debug message")
        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "\u{001B}[33mDEBUG:\u{001B}[0m this is a debug message\n")
    }

    func test_logInfo_With_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: true)
        logger.logInfo("this is an info message")
        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "\u{001B}[32mINFO:\u{001B}[0m this is an info message\n")
    }

    func test_logWarning_With_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: true)
        logger.logWarning("this is a warning message")
        XCTAssertEqual(stderr.output, "\u{001B}[35mWARNING:\u{001B}[0m this is a warning message\n")
        XCTAssertEqual(stdout.output, "")
    }

    func test_logError_With_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: true)
        logger.logError("this is an error message")
        XCTAssertEqual(stderr.output, "\u{001B}[31;1mERROR:\u{001B}[0m this is an error message\n")
        XCTAssertEqual(stdout.output, "")
    }

    // MARK: - Without Colors

    func test_logDebug_Without_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: false)
        logger.logDebug("this is a debug message")
        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "DEBUG: this is a debug message\n")
    }

    func test_logInfo_Without_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: false)
        logger.logInfo("this is an info message")
        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "INFO: this is an info message\n")
    }

    func test_logWarning_Without_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: false)
        logger.logWarning("this is a warning message")
        XCTAssertEqual(stderr.output, "WARNING: this is a warning message\n")
        XCTAssertEqual(stdout.output, "")
    }

    func test_logError_Without_Colors() {
        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(standardError: stderr, standardOutput: stdout, colorize: false)
        logger.logError("this is an error message")
        XCTAssertEqual(stderr.output, "ERROR: this is an error message\n")
        XCTAssertEqual(stdout.output, "")
    }
}
