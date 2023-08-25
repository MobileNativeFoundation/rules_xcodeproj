import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateLocalizedFileElementTests: XCTestCase {
    func test() {
        // Arrange

        let name = "Localized.strings"
        let path = "Base.lproj/Localized.strings"
        let ext = "strings"
        let bazelPath = BazelPath("some/Base.lproj/Localized.strings")

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: bazelPath.path,
                name: name,
                type: .localized
            )
        ]
        let stubbedIdentifier = "1234abcd"
        let createIdentifier = ElementCreator.CreateIdentifier
            .mock(identifier: stubbedIdentifier)

        let expectedElement = Element(
            name: name,
            object: .init(
                identifier: stubbedIdentifier,
                content: #"""
{isa = PBXFileReference; \#
lastKnownFileType = text.plist.strings; \#
name = Localized.strings; \#
path = Base.lproj/Localized.strings; \#
sourceTree = "<group>"; }
"""#
            ),
            sortOrder: .fileLike
        )

        // Act

        let element = ElementCreator.CreateLocalizedFileElement.defaultCallable(
            name: name,
            path: path,
            ext: ext,
            bazelPath: bazelPath,
            createIdentifier: createIdentifier.mock
        )

        // Assert

        XCTAssertNoDifference(
            createIdentifier.tracker.called,
            expectedCreateIdentifierCalled
        )
        XCTAssertNoDifference(element, expectedElement)
    }
}
