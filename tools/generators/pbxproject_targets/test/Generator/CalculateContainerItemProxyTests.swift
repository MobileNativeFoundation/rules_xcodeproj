import CustomDump
import XCTest

@testable import pbxproject_targets
@testable import PBXProj

class CalculateContainerItemProxyTests: XCTestCase {
    func test_notEscaped() {
        // Arrange

        let identifier = Identifiers.Targets.Identifier(
            name: "BazelDependencies",
            subIdentifier: .init(shard: "01", hash: "deadbeef"),
            full: "bd /* BazelDependencies */",
            withoutComment: "bd"
        )

        // The tabs for indenting are intentional
        let expectedContainerItemProxy = #"""
{
			isa = PBXContainerItemProxy;
			containerPortal = FF0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = bd;
			remoteInfo = BazelDependencies;
		}
"""#

        // Act

        let containerItemProxy = Generator.CalculateContainerItemProxy
            .defaultCallable(identifier: identifier)

        // Assert

        XCTAssertNoDifference(
            containerItemProxy,
            expectedContainerItemProxy
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

        // The tabs for indenting are intentional
        let expectedContainerItemProxy = #"""
{
			isa = PBXContainerItemProxy;
			containerPortal = FF0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = app;
			remoteInfo = "App (iOS)";
		}
"""#

        // Act

        let containerItemProxy = Generator.CalculateContainerItemProxy
            .defaultCallable(identifier: identifier)

        // Assert

        XCTAssertNoDifference(
            containerItemProxy,
            expectedContainerItemProxy
        )
    }
}
