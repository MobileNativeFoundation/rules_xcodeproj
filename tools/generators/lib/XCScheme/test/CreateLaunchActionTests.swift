import CustomDump
import XCScheme
import XCTest

final class CreateLaunchActionTests: XCTestCase {
    func test_basic() {
        // Arrange

        let buildConfiguration = "AppStore"

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "AppStore"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_commandLineArguments() {
        // Arrange

        let buildConfiguration = "Debug"
        let commandLineArguments: [CommandLineArgument] = [
            .init(value: "-ARGUMENT_3"),
            .init(value: ""),
            .init(value: "multi\nline\nargument"),
            .init(value: "ARGUMENT_Z", enabled: false),
            .init(value: "something with spaces"),
            .init(value: "'ARGUMENT 1'"),
        ]

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <CommandLineArguments>
         <CommandLineArgument
            argument = "-ARGUMENT_3"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "''"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "multi\&#10;line\&#10;argument"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "ARGUMENT_Z"
            isEnabled = "NO">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "something\ with\ spaces"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "\&apos;ARGUMENT\ 1\&apos;"
            isEnabled = "YES">
         </CommandLineArgument>
      </CommandLineArguments>
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            commandLineArguments: commandLineArguments
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_customWorkingDirectory() {
        // Arrange

        let buildConfiguration = "Release"
        let customWorkingDirectory = "$(SOME_VARIABLE)/some/path"

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "YES"
      customWorkingDirectory = "$(SOME_VARIABLE)/some/path"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            customWorkingDirectory: customWorkingDirectory
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_enableAddressSanitizer() {
        // Arrange

        let buildConfiguration = "Profile"
        let enableAddressSanitizer = true

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      enableAddressSanitizer = "YES"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
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
   <LaunchAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      enableThreadSanitizer = "YES"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
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
   <LaunchAction
      buildConfiguration = "Profile"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      enableUBSanitizer = "YES"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
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
                value: "$(BUILT_PRODUCTS_DIR)"
            ),
            .init(key: "VAR A\nZ", value: "Spaces spaces everywhere"),
            .init(key: "VAR1", value: "'Value 1'"),
            .init(key: "VARB", value: "multi\nline\nvalue"),
        ]

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BUILD_WORKING_DIRECTORY"
            value = "$(BUILT_PRODUCTS_DIR)"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "VAR A&#10;Z"
            value = "Spaces spaces everywhere"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "VAR1"
            value = "&apos;Value 1&apos;"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "VARB"
            value = "multi&#10;line&#10;value"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            environmentVariables: environmentVariables
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_runnable_hosted() {
        // Arrange

        let buildConfiguration = "Debug"
        let runnable = Runnable.hosted(
            buildableReference: .init(
                blueprintIdentifier: "HOSTED_BLUEPRINT_IDENTIFIER",
                buildableName: "HOSTED_BUILDABLE_NAME",
                blueprintName: "HOSTED_BLUEPRINT_NAME",
                referencedContainer: "HOSTED_REFERENCED_CONTAINER"
            ),
            hostBuildableReference: .init(
                blueprintIdentifier: "HOST_BLUEPRINT_IDENTIFIER",
                buildableName: "HOST_BUILDABLE_NAME",
                blueprintName: "HOST_BLUEPRINT_NAME",
                referencedContainer: "HOST_REFERENCED_CONTAINER"
            ),
            debuggingMode: 1,
            remoteBundleIdentifier: "com.apple.SOMETHING"
        )

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = ""
      selectedLauncherIdentifier = "Xcode.IDEFoundation.Launcher.PosixSpawn"
      launchStyle = "0"
      askForAppToLaunch = "YES"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
      launchAutomaticallySubstyle = "2">
      <RemoteRunnable
         runnableDebuggingMode = "1"
         BundleIdentifier = "com.apple.SOMETHING">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "HOSTED_BLUEPRINT_IDENTIFIER"
            BuildableName = "HOSTED_BUILDABLE_NAME"
            BlueprintName = "HOSTED_BLUEPRINT_NAME"
            ReferencedContainer = "HOSTED_REFERENCED_CONTAINER">
         </BuildableReference>
      </RemoteRunnable>
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "HOST_BLUEPRINT_IDENTIFIER"
            BuildableName = "HOST_BUILDABLE_NAME"
            BlueprintName = "HOST_BLUEPRINT_NAME"
            ReferencedContainer = "HOST_REFERENCED_CONTAINER">
         </BuildableReference>
      </MacroExpansion>
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            runnable: runnable
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_runnable_plain() {
        // Arrange

        let buildConfiguration = "Debug"
        let runnable = Runnable.plain(
            buildableReference: .init(
                blueprintIdentifier: "BLUEPRINT_IDENTIFIER",
                buildableName: "BUILDABLE_NAME",
                blueprintName: "BLUEPRINT_NAME",
                referencedContainer: "REFERENCED_CONTAINER"
            )
        )

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "BLUEPRINT_IDENTIFIER"
            BuildableName = "BUILDABLE_NAME"
            BlueprintName = "BLUEPRINT_NAME"
            ReferencedContainer = "REFERENCED_CONTAINER">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
"""#

        // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            runnable: runnable
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_runnable_path() {
         // Arrange
        let buildConfiguration = "Debug"
        let runnable = Runnable.path(path: "/Foo/Bar.app")

        let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <PathRunnable
         runnableDebuggingMode = "0"
         FilePath = "/Foo/Bar.app">
      </PathRunnable>
   </LaunchAction>
"""#

         // Act

        let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            runnable: runnable
         )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }

    func test_runnable_path_with_pre_and_postActions() {
         // Arrange

         let buildConfiguration = "Debug"
         let runnable = Runnable.path(path: "/Foo/Bar.app")
         let preActions: [ExecutionAction] = [
               .init(
                  title: "PRE_ACTION_TITLE",
                  escapedScriptText: "PRE_ACTION_SCRIPT_TEXT",
                  expandVariablesBasedOn: nil
               ),
         ]
         let postActions: [ExecutionAction] = [
               .init(
                  title: "POST_ACTION_TITLE",
                  escapedScriptText: "POST_ACTION_SCRIPT_TEXT",
                  expandVariablesBasedOn: nil
               ),
         ]

         let expectedAction = #"""
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "PRE_ACTION_TITLE"
               scriptText = "PRE_ACTION_SCRIPT_TEXT">
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <PostActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "POST_ACTION_TITLE"
               scriptText = "POST_ACTION_SCRIPT_TEXT">
            </ActionContent>
         </ExecutionAction>
      </PostActions>
      <PathRunnable
         runnableDebuggingMode = "0"
         FilePath = "/Foo/Bar.app">
      </PathRunnable>
   </LaunchAction>
"""#

         // Act

         let action = createLaunchActionWithDefaults(
            buildConfiguration: buildConfiguration,
            postActions: postActions,
            preActions: preActions,
            runnable: runnable
         )

         // Assert

         XCTAssertNoDifference(action, expectedAction)
    }
}

private func createLaunchActionWithDefaults(
    buildConfiguration: String,
    commandLineArguments: [CommandLineArgument] = [],
    customWorkingDirectory: String? = nil,
    enableAddressSanitizer: Bool = false,
    enableThreadSanitizer: Bool = false,
    enableUBSanitizer: Bool = false,
    environmentVariables: [EnvironmentVariable] = [],
    postActions: [ExecutionAction] = [],
    preActions: [ExecutionAction] = [],
    runnable: Runnable? = nil
) -> String {
    return CreateLaunchAction.defaultCallable(
        buildConfiguration: buildConfiguration,
        commandLineArguments: commandLineArguments,
        customWorkingDirectory: customWorkingDirectory,
        enableAddressSanitizer: enableAddressSanitizer,
        enableThreadSanitizer: enableThreadSanitizer,
        enableUBSanitizer: enableUBSanitizer,
        environmentVariables: environmentVariables,
        postActions: postActions,
        preActions: preActions,
        runnable: runnable
    )
}
