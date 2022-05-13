import XcodeProj
import XCTest

@testable import generator

class XCSchemeEnvironmentVariablesExtensionsTests: XCTestCase {
    func test_bazelLaunchVariables() throws {
        let result: [XCScheme.EnvironmentVariable] = .bazelLaunchVariables
        XCTAssertEqual(result.count, 2)

        let variableNames = Set(result.map(\.variable))
        XCTAssertEqual(
            variableNames,
            Set(["BUILD_WORKSPACE_DIRECTORY", "BUILD_WORKING_DIRECTORY"])
        )
    }

    func test_createBazelTestVariables() throws {
        let workspaceName = "MyBazelWorkspace"
        let result: [XCScheme.EnvironmentVariable] = .createBazelTestVariables(
            workspaceName: workspaceName
        )

        let indexedResult = Dictionary(
            uniqueKeysWithValues: result.map { ($0.variable, $0) }
        )
        XCTAssertEqual(indexedResult.count, 2)
        XCTAssertNotNil(indexedResult["TEST_SRCDIR"])
        guard let testWorkspace = indexedResult["TEST_WORKSPACE"] else {
            XCTFail("Expected to find TEST_WORKSPACE")
            return
        }
        XCTAssertEqual(testWorkspace.value, workspaceName)
    }
}
