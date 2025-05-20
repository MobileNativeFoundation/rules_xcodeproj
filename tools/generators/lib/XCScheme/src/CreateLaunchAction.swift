public struct CreateLaunchAction {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates the `LaunchAction` element of an Xcode scheme.
    public func callAsFunction(
        buildConfiguration: String,
        commandLineArguments: [CommandLineArgument],
        customWorkingDirectory: String?,
        enableAddressSanitizer: Bool,
        enableThreadSanitizer: Bool,
        enableUBSanitizer: Bool,
        enableMainThreadChecker: Bool,
        enableThreadPerformanceChecker: Bool,
        storeKitConfiguration: String?,
        environmentVariables: [EnvironmentVariable],
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        runnable: Runnable?
    ) -> String {
        return callable(
            /*buildConfiguration:*/ buildConfiguration,
            /*commandLineArguments:*/ commandLineArguments,
            /*customWorkingDirectory:*/ customWorkingDirectory,
            /*enableAddressSanitizer:*/ enableAddressSanitizer,
            /*enableThreadSanitizer:*/ enableThreadSanitizer,
            /*enableUBSanitizer:*/ enableUBSanitizer,
            /*enableMainThreadChecker:*/ enableMainThreadChecker,
            /*enableThreadPerformanceChecker:*/ enableThreadPerformanceChecker,
            /*storeKitConfiguration:*/ storeKitConfiguration,
            /*environmentVariables:*/ environmentVariables,
            /*postActions:*/ postActions,
            /*preActions:*/ preActions,
            /*runnable:*/ runnable
        )
    }
}

// MARK: - CreateLaunchAction.Callable

extension CreateLaunchAction {
    public typealias Callable = (
        _ buildConfiguration: String,
        _ commandLineArguments: [CommandLineArgument],
        _ customWorkingDirectory: String?,
        _ enableAddressSanitizer: Bool,
        _ enableThreadSanitizer: Bool,
        _ enableUBSanitizer: Bool,
        _ enableMainThreadChecker: Bool,
        _ enableThreadPerformanceChecker: Bool,
        _ storeKitConfiguration: String?,
        _ environmentVariables: [EnvironmentVariable],
        _ postActions: [ExecutionAction],
        _ preActions: [ExecutionAction],
        _ runnable: Runnable?
    ) -> String

    public static func defaultCallable(
        buildConfiguration: String,
        commandLineArguments: [CommandLineArgument],
        customWorkingDirectory: String?,
        enableAddressSanitizer: Bool,
        enableThreadSanitizer: Bool,
        enableUBSanitizer: Bool,
        enableMainThreadChecker: Bool,
        enableThreadPerformanceChecker: Bool,
        storeKitConfiguration: String?,
        environmentVariables: [EnvironmentVariable],
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        runnable: Runnable?
    ) -> String {
        // 3 spaces for indentation is intentional

        var components: [String] = [
            #"buildConfiguration = "\#(buildConfiguration)""#,
        ]

        let isHosted = runnable?.isHosted ?? false

        if isHosted {
            components.append(
                #"""
selectedDebuggerIdentifier = ""
      selectedLauncherIdentifier = "Xcode.IDEFoundation.Launcher.PosixSpawn"
"""#
            )
        } else {
            components.append(
                #"""
selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
"""#
            )
        }

        if enableAddressSanitizer {
            components.append(#"enableAddressSanitizer = "YES""#)
        }
        if enableThreadSanitizer {
            components.append(#"enableThreadSanitizer = "YES""#)
        }
        if enableUBSanitizer {
            components.append(#"enableUBSanitizer = "YES""#)
        }

        if !enableMainThreadChecker {
            components.append(#"disableMainThreadChecker = "YES""#)
        }
        if !enableThreadPerformanceChecker {
            components.append(#"disablePerformanceAntipatternChecker = "YES""#)
        }

        components.append(#"launchStyle = "0""#)

        if isHosted {
            components.append(#"askForAppToLaunch = "YES""#)
        }

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
            #"""
ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
"""#
        )

        if isHosted {
            components.append(#"launchAutomaticallySubstyle = "2""#)
        }

        let runnableString: String
        if let runnable = runnable {
            switch runnable {
            case let .path(path):
                runnableString = #"""
      <PathRunnable
         runnableDebuggingMode = "0"
         FilePath = "\#(path)">
      </PathRunnable>

"""#
            case let .plain(reference):
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
            case let .hosted(
                reference,
                hostReference,
                debuggingMode,
                bundleIdentifier
            ):
                runnableString = #"""
      <RemoteRunnable
         runnableDebuggingMode = "\#(debuggingMode)"
         BundleIdentifier = "\#(bundleIdentifier)">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "\#(reference.blueprintIdentifier)"
            BuildableName = "\#(reference.buildableName)"
            BlueprintName = "\#(reference.blueprintName)"
            ReferencedContainer = "\#(reference.referencedContainer)">
         </BuildableReference>
      </RemoteRunnable>
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "\#(hostReference.blueprintIdentifier)"
            BuildableName = "\#(hostReference.buildableName)"
            BlueprintName = "\#(hostReference.blueprintName)"
            ReferencedContainer = "\#(hostReference.referencedContainer)">
         </BuildableReference>
      </MacroExpansion>

"""#
            }
        } else {
            runnableString = ""
        }

        let storeKitConfigurationString: String
        if let storeKitConfiguration, storeKitConfiguration.count > 0, storeKitConfiguration != "None" {
            
        storeKitConfigurationString = #"""
      <StoreKitConfigurationFileReference
         identifier = "\#(storeKitConfiguration)">
      </StoreKitConfigurationFileReference>

"""#
        } else {
            storeKitConfigurationString = ""
        }

        return #"""
   <LaunchAction
      \#(components.joined(separator: "\n      "))>
\#(preActions.preActionsString)\#
\#(postActions.postActionsString)\#
\#(runnableString)\#
\#(storeKitConfigurationString)\#
\#(commandLineArguments.commandLineArgumentsString)\#
\#(environmentVariables.environmentVariablesString)\#
   </LaunchAction>
"""#
    }
}

private extension Runnable {
    var isHosted: Bool {
        switch self {
        case .path, .plain: return false
        case .hosted: return true
        }
    }
}
