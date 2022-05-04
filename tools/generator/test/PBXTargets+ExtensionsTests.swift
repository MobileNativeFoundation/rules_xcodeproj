import XcodeProj
import XCTest

@testable import generator

class PBXTargetsExtensionsTests: XCTestCase {
    let pbxNativeTarget = PBXNativeTarget(name: "foo")
    lazy var pbxTargets: [String: PBXTarget] = [
        "foo": pbxNativeTarget,
        "bar": PBXAggregateTarget(name: "bar"),
    ]

    func test_nativeTarget_whereKeyDoesNotExist() throws {
        XCTAssertNil(pbxTargets.nativeTarget("does_not_exist"))
    }

    func test_nativeTarget_whereKeyExistsButNotNativeTarget() throws {
        XCTAssertNil(pbxTargets.nativeTarget("bar"))
    }

    func test_nativeTarget_whereKeyExistxAndIsNativeTarget() throws {
        guard let actual = pbxTargets.nativeTarget("foo") else {
            XCTFail("Expected to find `foo`")
            return
        }
        XCTAssertEqual(actual, pbxNativeTarget)
    }
}
