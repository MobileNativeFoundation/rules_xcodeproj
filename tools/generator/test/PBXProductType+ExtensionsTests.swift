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

    func test_createBazelTestEnvironmentVariables_WhenIsTestBundle() throws {
        let workspaceName = "bazel_workspace"
        XCTAssertEqual(
            PBXProductType.unitTestBundle.createBazelTestEnvironmentVariables(
                workspaceName: workspaceName
            ),
            .createBazelTestVariables(workspaceName: workspaceName)
        )
    }

    func test_createBazelTestEnvironmentVariables_WhenIsNotTestBundle() throws {
        let workspaceName = "bazel_workspace"
        XCTAssertNil(
            PBXProductType.application.createBazelTestEnvironmentVariables(
                workspaceName: workspaceName
            )
        )
    }
}
