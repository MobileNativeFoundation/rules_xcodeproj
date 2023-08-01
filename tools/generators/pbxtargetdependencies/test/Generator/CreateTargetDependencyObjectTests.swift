import CustomDump
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

class CreateTargetDependencyObjectTests: XCTestCase {
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
        let containerItemProxyIdentifier = "bd_cip /* CIP */"

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: """
FROM_SHARD02FROM_HASHTO_SHARD00TO_HASH /* PBXTargetDependency */
""",
            content: #"""
{
			isa = PBXTargetDependency;
			name = BazelDependencies;
			target = bd /* BazelDependencies */;
			targetProxy = bd_cip /* CIP */;
		}
"""#
        )

        // Act

        let object = Generator.CreateTargetDependencyObject.defaultCallable(
            from: subIdentifier,
            to: dependencyIdentifier,
            containerItemProxyIdentifier: containerItemProxyIdentifier
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
        let containerItemProxyIdentifier = "bd_cip /* CIP */"

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: """
FROM_SHARD02FROM_HASHTO_SHARD00TO_HASH /* PBXTargetDependency */
""",
            content: #"""
{
			isa = PBXTargetDependency;
			name = "App (iOS)";
			target = app /* App */;
			targetProxy = bd_cip /* CIP */;
		}
"""#
        )

        // Act

        let object = Generator.CreateTargetDependencyObject.defaultCallable(
            from: subIdentifier,
            to: dependencyIdentifier,
            containerItemProxyIdentifier: containerItemProxyIdentifier
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
