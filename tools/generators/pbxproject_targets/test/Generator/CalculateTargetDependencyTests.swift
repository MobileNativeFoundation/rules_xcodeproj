import CustomDump
import XCTest

@testable import pbxproject_targets
@testable import PBXProj

class CalculateTargetDependencyTests: XCTestCase {
    func test_notEscaped() {
        // Arrange

        let identifier = Identifiers.Targets.Identifier(
            name: "BazelDependencies",
            subIdentifier: .init(shard: "01", hash: "deadbeef"),
            full: "bd /* BazelDependencies */",
            withoutComment: "bd"
        )
        let containerItemProxyIdentifier = "bd_cip /* CIP */"

        // The tabs for indenting are intentional
        let expectedTargetDependency = #"""
{
			isa = PBXTargetDependency;
			name = BazelDependencies;
			target = bd /* BazelDependencies */;
			targetProxy = bd_cip /* CIP */;
		}
"""#

        // Act

        let targetDependency = Generator.CalculateTargetDependency
            .defaultCallable(
                identifier: identifier,
                containerItemProxyIdentifier: containerItemProxyIdentifier
            )

        // Assert

        XCTAssertNoDifference(
            targetDependency,
            expectedTargetDependency
        )
    }

    func test_escaped() {
        // Arrange

        let identifier = Identifiers.Targets.Identifier(
            name: "App (iOS)".pbxProjEscaped,
            subIdentifier: .init(shard: "07", hash: "beefdead"),
            full: "app /* App */",
            withoutComment: "app"
        )
        let containerItemProxyIdentifier = "bd_cip /* CIP */"

        // The tabs for indenting are intentional
        let expectedTargetDependency = #"""
{
			isa = PBXTargetDependency;
			name = "App (iOS)";
			target = app /* App */;
			targetProxy = bd_cip /* CIP */;
		}
"""#

        // Act

        let targetDependency = Generator.CalculateTargetDependency
            .defaultCallable(
                identifier: identifier,
                containerItemProxyIdentifier: containerItemProxyIdentifier
            )

        // Assert

        XCTAssertNoDifference(
            targetDependency,
            expectedTargetDependency
        )
    }
}
