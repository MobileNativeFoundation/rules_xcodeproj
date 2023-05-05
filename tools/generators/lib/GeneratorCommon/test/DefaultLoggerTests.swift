import GeneratorCommon
import XCTest

/// A `TextOutputStream` that writes to a string.
final class StringOutputStream: TextOutputStream {
    private(set) var output = ""

    func write(_ string: String) {
        output += string
    }
}

final class DefaultLoggerTests: XCTestCase {

    // MARK: With colors

    func test_logDebug_withColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: true
        )

        // Act

        logger.logDebug("this is a debug message")

        // Assert

        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(
            stdout.output,
            "\u{001B}[33mDEBUG:\u{001B}[0m this is a debug message\n"
        )
    }

    func test_logInfo_withColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: true
        )

        // Act

        logger.logInfo("this is an info message")

        // Assert

        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(
            stdout.output,
            "\u{001B}[32mINFO:\u{001B}[0m this is an info message\n"
        )
    }

    func test_logWarning_withColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: true
        )

        // Act

        logger.logWarning("this is a warning message")

        // Assert

        XCTAssertEqual(
            stderr.output,
            "\u{001B}[35mWARNING:\u{001B}[0m this is a warning message\n"
        )
        XCTAssertEqual(stdout.output, "")
    }

    func test_logError_withColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: true
        )

        // Act

        logger.logError("this is an error message")

        // Assert

        XCTAssertEqual(
            stderr.output,
            "\u{001B}[31;1mERROR:\u{001B}[0m this is an error message\n"
        )
        XCTAssertEqual(stdout.output, "")
    }

    // MARK: Without colors

    func test_logDebug_withoutColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: false
        )

        // Act

        logger.logDebug("this is a debug message")

        // Assert

        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "DEBUG: this is a debug message\n")
    }

    func test_logInfo_withoutColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: false
        )

        // Act

        logger.logInfo("this is an info message")

        // Assert

        XCTAssertEqual(stderr.output, "")
        XCTAssertEqual(stdout.output, "INFO: this is an info message\n")
    }

    func test_logWarning_withoutColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: false
        )

        // Act

        logger.logWarning("this is a warning message")

        // Assert

        XCTAssertEqual(stderr.output, "WARNING: this is a warning message\n")
        XCTAssertEqual(stdout.output, "")
    }

    func test_logError_withoutColors() {
        // Arrange

        let stderr = StringOutputStream()
        let stdout = StringOutputStream()
        let logger = DefaultLogger(
            standardError: stderr,
            standardOutput: stdout,
            colorize: false
        )

        // Act

        logger.logError("this is an error message")

        // Assert

        XCTAssertEqual(stderr.output, "ERROR: this is an error message\n")
        XCTAssertEqual(stdout.output, "")
    }
}
