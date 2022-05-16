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
}
