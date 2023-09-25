public struct CreateProfileAction {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates the `ProfileAction` element of an Xcode scheme.
    public func callAsFunction(
        buildConfiguration: String,
        commandLineArguments: [CommandLineArgument],
        customWorkingDirectory: String?,
        environmentVariables: [EnvironmentVariable],
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        useLaunchSchemeArgsEnv: Bool,
        runnable: Runnable?
    ) -> String {
        return callable(
            /*buildConfiguration:*/ buildConfiguration,
            /*commandLineArguments:*/ commandLineArguments,
            /*customWorkingDirectory:*/ customWorkingDirectory,
            /*environmentVariables:*/ environmentVariables,
            /*postActions:*/ postActions,
            /*preActions:*/ preActions,
            /*useLaunchSchemeArgsEnv:*/ useLaunchSchemeArgsEnv,
            /*runnable:*/ runnable
        )
    }
}

// MARK: - CreateProfileAction.Callable

extension CreateProfileAction {
    public typealias Callable = (
        _ buildConfiguration: String,
        _ commandLineArguments: [CommandLineArgument],
        _ customWorkingDirectory: String?,
        _ environmentVariables: [EnvironmentVariable],
        _ postActions: [ExecutionAction],
        _ preActions: [ExecutionAction],
        _ useLaunchSchemeArgsEnv: Bool,
        _ runnable: Runnable?
    ) -> String

    public static func defaultCallable(
        buildConfiguration: String,
        commandLineArguments: [CommandLineArgument],
        customWorkingDirectory: String?,
        environmentVariables: [EnvironmentVariable],
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        useLaunchSchemeArgsEnv: Bool,
        runnable: Runnable?
    ) -> String {
        // 3 spaces for indentation is intentional

        var components: [String] = [
            #"""
buildConfiguration = "\#(buildConfiguration)"
      shouldUseLaunchSchemeArgsEnv = "\#(useLaunchSchemeArgsEnv.xmlString)"
      savedToolIdentifier = ""
"""#,
        ]

        if let customWorkingDirectory {
            components.append(
                #"""
useCustomWorkingDirectory = "YES"
      customWorkingDirectory = "\#(customWorkingDirectory)"
"""#
            )
        } else {
            components.append(#"useCustomWorkingDirectory = "NO""#)
        }

        components.append(
            #"debugDocumentVersioning = "YES""#
        )

        let runnableString: String
        if let runnable = runnable {
            switch runnable {
            case let .plain(reference), let .hosted(reference, _, _, _):
                runnableString = #"""
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "\#(reference.blueprintIdentifier)"
            BuildableName = "\#(reference.buildableName)"
            BlueprintName = "\#(reference.blueprintName)"
            ReferencedContainer = "\#(reference.referencedContainer)">
         </BuildableReference>
      </BuildableProductRunnable>

"""#
            }
        } else {
            runnableString = ""
        }

        return #"""
   <ProfileAction
      \#(components.joined(separator: "\n      "))>
\#(preActions.preActionsString)\#
\#(postActions.postActionsString)\#
\#(runnableString)\#
\#(commandLineArguments.commandLineArgumentsString)\#
\#(environmentVariables.environmentVariablesString)\#
   </ProfileAction>
"""#
    }
}
