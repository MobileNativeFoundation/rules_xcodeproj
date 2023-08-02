import CustomDump
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

class CreateContainerItemProxyObjectTests: XCTestCase {
    func test_notEscaped() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "FROM_SHARD",
            hash: "FROM_HASH"
        )
        let dependencyIdentifier = Identifiers.Targets.Identifier(
            pbxProjEscapedName: "BazelDependencies",
            subIdentifier: .init(shard: "TO_SHARD", hash: "TO_HASH"),
            full: "bd /* BazelDependencies */",
            withoutComment: "bd"
        )

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: """
FROM_SHARD01FROM_HASHTO_SHARD00TO_HASH /* PBXContainerItemProxy */
""",
            content: #"""
{
			isa = PBXContainerItemProxy;
			containerPortal = FF0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = bd;
			remoteInfo = BazelDependencies;
		}
"""#

        )

        // Act

        let object = Generator.CreateContainerItemProxyObject.defaultCallable(
            from: subIdentifier,
            to: dependencyIdentifier
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }

    func test_escaped() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "FROM_SHARD",
            hash: "FROM_HASH"
        )
        let dependencyIdentifier = Identifiers.Targets.Identifier(
            pbxProjEscapedName: "App (iOS)".pbxProjEscaped,
            subIdentifier: .init(shard: "TO_SHARD", hash: "TO_HASH"),
            full: "app /* App */",
            withoutComment: "app"
        )

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: """
FROM_SHARD01FROM_HASHTO_SHARD00TO_HASH /* PBXContainerItemProxy */
""",
            content: #"""
{
			isa = PBXContainerItemProxy;
			containerPortal = FF0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = app;
			remoteInfo = "App (iOS)";
		}
"""#
        )

        // Act

        let object = Generator.CreateContainerItemProxyObject.defaultCallable(
            from: subIdentifier,
            to: dependencyIdentifier
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
