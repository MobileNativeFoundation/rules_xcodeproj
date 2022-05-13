import XcodeProj
import XCTest

@testable import generator

class PBXProductTypeExtensionsTests: XCTestCase {
    func test_bazelLaunchEnvironmentVariables_WhenIsLaunchable() throws {
        XCTAssertEqual(
            PBXProductType.application.bazelLaunchEnvironmentVariables,
            .bazelLaunchVariables
        )
    }

    func test_bazelLaunchEnvironmentVariables_WhenIsNotLaunchable() throws {
        XCTAssertNil(PBXProductType.framework.bazelLaunchEnvironmentVariables)
    }

    func test_bazelTestEnvironmentVariables_WhenIsTestBundle() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_bazelTestEnvironmentVariables_WhenIsNotTestBundle() throws {
        XCTFail("IMPLEMENT ME!")
    }
}
