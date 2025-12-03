import CustomDump
import XCScheme
import XCTest

final class CreateTestActionTests: XCTestCase {
    func test_basic() {
        // Arrange

        let buildConfiguration = "AppStore"

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "AppStore"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_commandLineArguments() {
        // Arrange

        let buildConfiguration = "Debug"
        let commandLineArguments: [CommandLineArgument] = [
            .init(value: "-ARGUMENT_1"),
            .init(value: "ARGUMENT_A", isEnabled: false),
            .init(value: "'ARGUMENT 2'"),
        ]

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <CommandLineArguments>
         <CommandLineArgument
            argument = "-ARGUMENT_1"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "ARGUMENT_A"
            isEnabled = "NO">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "\&apos;ARGUMENT\ 2\&apos;"
            isEnabled = "YES">
         </CommandLineArgument>
      </CommandLineArguments>
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            commandLineArguments: commandLineArguments
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_disableMainThreadChecker() {
        // Arrange

        let buildConfiguration = "Profile"
        let enableMainThreadChecker = false

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      disableMainThreadChecker = "YES">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            enableMainThreadChecker: enableMainThreadChecker
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_enableAddressSanitizer() {
        // Arrange

        let buildConfiguration = "Profile"
        let enableAddressSanitizer = true

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      enableAddressSanitizer = "YES">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            enableAddressSanitizer: enableAddressSanitizer
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_enableThreadSanitizer() {
        // Arrange

        let buildConfiguration = "Profile"
        let enableThreadSanitizer = true

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      enableThreadSanitizer = "YES">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            enableThreadSanitizer: enableThreadSanitizer
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_enableUBSanitizer() {
        // Arrange

        let buildConfiguration = "Profile"
        let enableUBSanitizer = true

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      enableUBSanitizer = "YES">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            enableUBSanitizer: enableUBSanitizer
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_environmentVariables() {
        // Arrange

        let buildConfiguration = "Debug"
        let environmentVariables: [EnvironmentVariable] = [
            .init(
                key: "BUILD_WORKING_DIRECTORY",
                value: "$(BUILT_PRODUCTS_DIR)",
                isEnabled: false
            ),
            .init(key: "VAR", value: "'Value 1'"),
        ]

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BUILD_WORKING_DIRECTORY"
            value = "$(BUILT_PRODUCTS_DIR)"
            isEnabled = "NO">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "VAR"
            value = "&apos;Value 1&apos;"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            environmentVariables: environmentVariables
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_expandVariablesBasedOn() {
        // Arrange

        let buildConfiguration = "AppStore"
        let macroReference = BuildableReference(
            blueprintIdentifier: "BLUEPRINT_IDENTIFIER",
            buildableName: "BUILDABLE_NAME",
            blueprintName: "BLUEPRINT_NAME",
            referencedContainer: "REFERENCED_CONTAINER"
        )

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "AppStore"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "BLUEPRINT_IDENTIFIER"
            BuildableName = "BUILDABLE_NAME"
            BlueprintName = "BLUEPRINT_NAME"
            ReferencedContainer = "REFERENCED_CONTAINER">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            expandVariablesBasedOn: macroReference
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_testables() {
        // Arrange

        let buildConfiguration = "Debug"
        let testables: [Testable] = [
            .init(
                buildableReference: .init(
                    blueprintIdentifier: "BLUEPRINT_IDENTIFIER_3",
                    buildableName: "BUILDABLE_NAME_3",
                    blueprintName: "BLUEPRINT_NAME_3",
                    referencedContainer: "REFERENCED_CONTAINER_3"
                ),
                isSkipped: false
            ),
            .init(
                buildableReference: .init(
                    blueprintIdentifier: "BLUEPRINT_IDENTIFIER_1",
                    buildableName: "BUILDABLE_NAME_1",
                    blueprintName: "BLUEPRINT_NAME_1",
                    referencedContainer: "REFERENCED_CONTAINER_1"
                ),
                isSkipped: true
            ),
        ]

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "BLUEPRINT_IDENTIFIER_3"
               BuildableName = "BUILDABLE_NAME_3"
               BlueprintName = "BLUEPRINT_NAME_3"
               ReferencedContainer = "REFERENCED_CONTAINER_3">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "BLUEPRINT_IDENTIFIER_1"
               BuildableName = "BUILDABLE_NAME_1"
               BlueprintName = "BLUEPRINT_NAME_1"
               ReferencedContainer = "REFERENCED_CONTAINER_1">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            testables: testables
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_noUseLaunchSchemeArgsEnv() {
        // Arrange

        let buildConfiguration = "Release"
        let useLaunchSchemeArgsEnv = false

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "NO">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            buildConfiguration: buildConfiguration,
            useLaunchSchemeArgsEnv: useLaunchSchemeArgsEnv
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_appLanguageAndAppRegion() {
        // Arrange

        let buildConfiguration = "Release"
        let useLaunchSchemeArgsEnv = false

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "NO"
      language = "en"
      region = "US">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            appLanguage: "en",
            appRegion: "US",
            buildConfiguration: buildConfiguration,
            useLaunchSchemeArgsEnv: useLaunchSchemeArgsEnv
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }
    
    func test_codeCoverageEnable() {
        // Arrange

        let buildConfiguration = "Release"
        let useLaunchSchemeArgsEnv = false

        let expectedAction = #"""
   <TestAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "NO"
      language = "en"
      region = "US">
      <Testables>
      </Testables>
   </TestAction>
"""#

        // Act

        let action = createTestActionWithDefaults(
            appLanguage: "en",
            appRegion: "US",
            buildConfiguration: buildConfiguration,
            useLaunchSchemeArgsEnv: useLaunchSchemeArgsEnv
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }
}

private func createTestActionWithDefaults(
    appLanguage: String? = nil,
    appRegion: String? = nil,
    codeCoverage: Bool = false,
    buildConfiguration: String,
    commandLineArguments: [CommandLineArgument] = [],
    enableAddressSanitizer: Bool = false,
    enableThreadSanitizer: Bool = false,
    enableUBSanitizer: Bool = false,
    enableMainThreadChecker: Bool = true,
    enableThreadPerformanceChecker: Bool = true,
    environmentVariables: [EnvironmentVariable] = [],
    expandVariablesBasedOn macroReference: BuildableReference? = nil,
    postActions: [ExecutionAction] = [],
    preActions: [ExecutionAction] = [],
    testables: [Testable] = [],
    useLaunchSchemeArgsEnv: Bool = true
) -> String {
    return CreateTestAction.defaultCallable(
        appLanguage: appLanguage,
        appRegion: appRegion,
        codeCoverage: codeCoverage,
        buildConfiguration: buildConfiguration,
        commandLineArguments: commandLineArguments,
        enableAddressSanitizer: enableAddressSanitizer,
        enableThreadSanitizer: enableThreadSanitizer,
        enableUBSanitizer: enableUBSanitizer,
        enableMainThreadChecker: enableMainThreadChecker,
        enableThreadPerformanceChecker: enableThreadPerformanceChecker,
        environmentVariables: environmentVariables,
        expandVariablesBasedOn: macroReference,
        postActions: postActions,
        preActions: preActions,
        testables: testables,
        useLaunchSchemeArgsEnv: useLaunchSchemeArgsEnv
    )
}
