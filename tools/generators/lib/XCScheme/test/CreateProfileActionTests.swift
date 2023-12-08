import CustomDump
import XCScheme
import XCTest

final class CreateProfileActionTests: XCTestCase {
    func test_basic() {
        // Arrange

        let buildConfiguration = "AppStore"

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "AppStore"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
    }

    func test_commandLineArguments() {
        // Arrange

        let buildConfiguration = "Debug"
        let commandLineArguments: [CommandLineArgument] = [
            .init(value: "-ARGUMENT_42"),
            .init(value: "ARGUMENT_F", enabled: false),
            .init(value: "'ARGUMENT 3'"),
        ]

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Debug"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <CommandLineArguments>
         <CommandLineArgument
            argument = "-ARGUMENT_42"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "ARGUMENT_F"
            isEnabled = "NO">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "\&apos;ARGUMENT\ 3\&apos;"
            isEnabled = "YES">
         </CommandLineArgument>
      </CommandLineArguments>
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            commandLineArguments: commandLineArguments
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
    }

    func test_customWorkingDirectory() {
        // Arrange

        let buildConfiguration = "Profile"
        let customWorkingDirectory = "$(SOME_VARIABLE)/some/path"

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Profile"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "YES"
      customWorkingDirectory = "$(SOME_VARIABLE)/some/path"
      debugDocumentVersioning = "YES">
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            customWorkingDirectory: customWorkingDirectory
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
    }

    func test_environmentVariables() {
        // Arrange

        let buildConfiguration = "Debug"
        let environmentVariables: [EnvironmentVariable] = [
            .init(
                key: "BUILD_WORKING_DIRECTORY",
                value: "$(BUILT_PRODUCTS_DIR)"
            ),
            .init(key: "VAR", value: "'Value 1'"),
        ]

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Debug"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BUILD_WORKING_DIRECTORY"
            value = "$(BUILT_PRODUCTS_DIR)"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "VAR"
            value = "&apos;Value 1&apos;"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            environmentVariables: environmentVariables
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
    }

    func test_noUseLaunchSchemeArgsEnv() {
        // Arrange

        let buildConfiguration = "Release"
        let useLaunchSchemeArgsEnv = false

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "NO"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            useLaunchSchemeArgsEnv: useLaunchSchemeArgsEnv
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
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
            debuggingMode: 2,
            remoteBundleIdentifier: "com.apple.SOMETHING"
        )

        // The profile action doesn't use RemoteRunnable for hosted targets
        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Debug"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "HOSTED_BLUEPRINT_IDENTIFIER"
            BuildableName = "HOSTED_BUILDABLE_NAME"
            BlueprintName = "HOSTED_BLUEPRINT_NAME"
            ReferencedContainer = "HOSTED_REFERENCED_CONTAINER">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            runnable: runnable
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
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

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Debug"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
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
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            runnable: runnable
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
    }

    func test_runnable_path() {
        // Arrange

        let buildConfiguration = "Debug"
        let runnable = Runnable.path(path: "/Foo/Bar")

        let expectedPrefix = #"""
   <ProfileAction
      buildConfiguration = "Debug"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <PathRunnable
         runnableDebuggingMode = "0"
         FilePath = "/Foo/Bar">
      </PathRunnable>
   </ProfileAction>
"""#

        // Act

        let prefix = createProfileActionWithDefaults(
            buildConfiguration: buildConfiguration,
            runnable: runnable
        )

        // Assert

        XCTAssertNoDifference(prefix, expectedPrefix)
    }
}

private func createProfileActionWithDefaults(
    buildConfiguration: String,
    commandLineArguments: [CommandLineArgument] = [],
    customWorkingDirectory: String? = nil,
    environmentVariables: [EnvironmentVariable] = [],
    postActions: [ExecutionAction] = [],
    preActions: [ExecutionAction] = [],
    useLaunchSchemeArgsEnv: Bool = true,
    runnable: Runnable? = nil
) -> String {
    return CreateProfileAction.defaultCallable(
        buildConfiguration: buildConfiguration,
        commandLineArguments: commandLineArguments,
        customWorkingDirectory: customWorkingDirectory,
        environmentVariables: environmentVariables,
        postActions: postActions,
        preActions: preActions,
        useLaunchSchemeArgsEnv: useLaunchSchemeArgsEnv,
        runnable: runnable
    )
}
