import XCTest

@testable import generator

final class DefaultLoggerTests: XCTestCase {
    func test_logDebug() {
        let logger = DefaultLogger()
        let stream = StringOutputStream()
        logger.overrideOutputStreamForTests(stream)
        logger.logDebug("this is a debug message")
        XCTAssertEqual(stream.output, "DEBUG: this is a debug message\n")
    }

    func test_logInfo() {
        let logger = DefaultLogger()
        let stream = StringOutputStream()
        logger.overrideOutputStreamForTests(stream)
        logger.logInfo("this is an info message")
        XCTAssertEqual(stream.output, "INFO: this is an info message\n")
    }

    func test_logWarning() {
        let logger = DefaultLogger()
        let stream = StringOutputStream()
        logger.overrideOutputStreamForTests(stream)
        logger.logWarning("this is a warning message")
        XCTAssertEqual(stream.output, "WARNING: this is a warning message\n")
    }

    func test_logError() {
        let logger = DefaultLogger()
        let stream = StringOutputStream()
        logger.overrideOutputStreamForTests(stream)
        logger.logError("this is an error message")
        XCTAssertEqual(stream.output, "ERROR: this is an error message\n")
    }
}
