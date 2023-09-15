import CustomDump
import XCScheme
import XCTest

final class CreateSchemeTests: XCTestCase {
    func test_basic() {
        // Arrange

        let buildAction = #"""
   <BuildAction foo />
"""#
        let testAction = #"""
   <TestAction bar />
"""#
        let launchAction = #"""
   <LaunchAction baz />
"""#
        let profileAction = #"""
   <ProfileAction zab />
"""#
        let analyzeAction = #"""
   <AnalyzeAction rab />
"""#
        let archiveAction = #"""
   <ArchiveAction oof />
"""#
        let wasCreatedForAppExtension = false

        let expectedScheme = #"""
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "9999"
   version = "1.7">
   <BuildAction foo />
   <TestAction bar />
   <LaunchAction baz />
   <ProfileAction zab />
   <AnalyzeAction rab />
   <ArchiveAction oof />
</Scheme>

"""#

        // Act

        let scheme = CreateScheme.defaultCallable(
            buildAction: buildAction,
            testAction: testAction,
            launchAction: launchAction,
            profileAction: profileAction,
            analyzeAction: analyzeAction,
            archiveAction: archiveAction,
            wasCreatedForAppExtension: wasCreatedForAppExtension
        )

        // Assert

        XCTAssertNoDifference(scheme, expectedScheme)
    }

    func test_wasCreatedForAppExtension() {
        // Arrange

        let buildAction = #"""
   <BuildAction foo />
"""#
        let testAction = #"""
   <TestAction bar />
"""#
        let launchAction = #"""
   <LaunchAction baz />
"""#
        let profileAction = #"""
   <ProfileAction zab />
"""#
        let analyzeAction = #"""
   <AnalyzeAction rab />
"""#
        let archiveAction = #"""
   <ArchiveAction oof />
"""#
        let wasCreatedForAppExtension = true

        let expectedScheme = #"""
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "9999"
   wasCreatedForAppExtension = "YES"
   version = "2.0">
   <BuildAction foo />
   <TestAction bar />
   <LaunchAction baz />
   <ProfileAction zab />
   <AnalyzeAction rab />
   <ArchiveAction oof />
</Scheme>

"""#

        // Act

        let scheme = CreateScheme.defaultCallable(
            buildAction: buildAction,
            testAction: testAction,
            launchAction: launchAction,
            profileAction: profileAction,
            analyzeAction: analyzeAction,
            archiveAction: archiveAction,
            wasCreatedForAppExtension: wasCreatedForAppExtension
        )

        // Assert

        XCTAssertNoDifference(scheme, expectedScheme)
    }
}
