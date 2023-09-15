import CustomDump
import XCScheme
import XCTest

final class CreateBuildActionTests: XCTestCase {
    func test_entries() {
        // Arrange

        let entries: [BuildActionEntry] = [
            .init(
                buildableReference: .init(
                    blueprintIdentifier: "BLUEPRINT_IDENTIFIER_3",
                    buildableName: "BUILDABLE_NAME_3",
                    blueprintName: "BLUEPRINT_NAME_3",
                    referencedContainer: "REFERENCED_CONTAINER_3"
                ),
                buildFor: [.testing, .profiling, .analyzing]
            ),
            .init(
                buildableReference: .init(
                    blueprintIdentifier: "BLUEPRINT_IDENTIFIER_1",
                    buildableName: "BUILDABLE_NAME_1",
                    blueprintName: "BLUEPRINT_NAME_1",
                    referencedContainer: "REFERENCED_CONTAINER_1"
                ),
                buildFor: [.running, .archiving]
            ),
        ]

        let expectedAction = #"""
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "NO">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "YES"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "BLUEPRINT_IDENTIFIER_3"
               BuildableName = "BUILDABLE_NAME_3"
               BlueprintName = "BLUEPRINT_NAME_3"
               ReferencedContainer = "REFERENCED_CONTAINER_3">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "NO"
            buildForRunning = "YES"
            buildForProfiling = "NO"
            buildForArchiving = "YES"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "BLUEPRINT_IDENTIFIER_1"
               BuildableName = "BUILDABLE_NAME_1"
               BlueprintName = "BLUEPRINT_NAME_1"
               ReferencedContainer = "REFERENCED_CONTAINER_1">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
"""#

        // Act

        let action = createBuildActionWithDefaults(
            entries: entries
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }
}

private func createBuildActionWithDefaults(
    entries: [BuildActionEntry],
    postActions: [ExecutionAction] = [],
    preActions: [ExecutionAction] = []
) -> String {
    return CreateBuildAction.defaultCallable(
        entries: entries,
        postActions: postActions,
        preActions: preActions
    )
}
