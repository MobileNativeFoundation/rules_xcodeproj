import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateInlineBazelGeneratedConfigGroupElementTests: XCTestCase {
    
    func test_element_identifier() {
        let configName = "ios-sim-config123"
        let bazelPath = BazelPath("bazel-out/ios-sim-config123/bin")


        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: bazelPath.path,
                name: configName,
                type: .group
            )
        ]
        let stubbedIdentifier = "ios-sim-config123-identifier"
        let createIdentifier = ElementCreator.CreateIdentifier
            .mock(identifier: stubbedIdentifier)
        
        let result = ElementCreator.CreateInlineBazelGeneratedConfigGroupElement.defaultCallable(
            name: configName,
            path: bazelPath.path,
            bazelPath: bazelPath,
            childIdentifiers: [],
            createIdentifier: createIdentifier.mock
        )

        XCTAssertNoDifference(
            createIdentifier.tracker.called,
            expectedCreateIdentifierCalled
        )
        XCTAssertEqual(result.object.identifier, stubbedIdentifier)
    }


    func test_element_sortOrder() {
        let configName = "ios-sim-config123"
        let bazelPath = BazelPath("bazel-out/ios-sim-config123/bin")

        let result = ElementCreator.CreateInlineBazelGeneratedConfigGroupElement.defaultCallable(
            name: configName,
            path: bazelPath.path,
            bazelPath: bazelPath,
            childIdentifiers: [],
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        XCTAssertEqual(result.sortOrder, .groupLike)
    }
}

