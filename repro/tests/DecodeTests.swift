import PathKit
import XCTest

@testable import repro

final class DecodeTests: XCTestCase {
    func test_default() {
        guard let pathString = ProcessInfo.processInfo.environment["SPEC_PATH"] else {
            XCTFail("Please set the SPEC_PATH environment variable to the path of the spec to decode.")
            return
        }
        let path = Path(pathString)

       measure {
            do {
                _ = try readProject(path: path, useZippy: false)
            } catch {
                XCTFail(error.localizedDescription)
            }
       }
    }

    func test_zippy() {
        guard let pathString = ProcessInfo.processInfo.environment["SPEC_PATH"] else {
            XCTFail("Please set the SPEC_PATH environment variable to the path of the spec to decode.")
            return
        }
        let path = Path(pathString)

       measure {
            do {
                _ = try readProject(path: path, useZippy: true)
            } catch {
                XCTFail(error.localizedDescription)
            }
       }
    }
}
