public struct CreateTestAction {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates the `TestAction` element of an Xcode scheme.
    public func callAsFunction(
        buildConfiguration: String,
        commandLineArguments: [String],
        enableAddressSanitizer: Bool,
        enableThreadSanitizer: Bool,
        enableUBSanitizer: Bool,
        environmentVariables: [EnvironmentVariable],
        expandVariablesBasedOn: BuildableReference?,
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        testables: [Testable],
        useLaunchSchemeArgsEnv: Bool
    ) -> String {
        return callable(
            /*buildConfiguration:*/ buildConfiguration,
            /*commandLineArguments:*/ commandLineArguments,
            /*enableAddressSanitizer:*/ enableAddressSanitizer,
            /*enableThreadSanitizer:*/ enableThreadSanitizer,
            /*enableUBSanitizer:*/ enableUBSanitizer,
            /*environmentVariables:*/ environmentVariables,
            /*expandVariablesBasedOn:*/ expandVariablesBasedOn,
            /*postActions:*/ postActions,
            /*preActions:*/ preActions,
            /*testables:*/ testables,
            /*useLaunchSchemeArgsEnv:*/ useLaunchSchemeArgsEnv
        )
    }
}

// MARK: - CreateTestAction.Callable

extension CreateTestAction {
    public typealias Callable = (
        _ buildConfiguration: String,
        _ commandLineArguments: [String],
        _ enableAddressSanitizer: Bool,
        _ enableThreadSanitizer: Bool,
        _ enableUBSanitizer: Bool,
        _ environmentVariables: [EnvironmentVariable],
        _ expandVariablesBasedOn: BuildableReference?,
        _ postActions: [ExecutionAction],
        _ preActions: [ExecutionAction],
        _ testables: [Testable],
        _ useLaunchSchemeArgsEnv: Bool
    ) -> String

    public static func defaultCallable(
        buildConfiguration: String,
        commandLineArguments: [String],
        enableAddressSanitizer: Bool,
        enableThreadSanitizer: Bool,
        enableUBSanitizer: Bool,
        environmentVariables: [EnvironmentVariable],
        expandVariablesBasedOn macroReference: BuildableReference?,
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        testables: [Testable],
        useLaunchSchemeArgsEnv: Bool
    ) -> String {
        // 3 spaces for indentation is intentional

        var components: [String] = [
            #"""
buildConfiguration = "\#(buildConfiguration)"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "\#(useLaunchSchemeArgsEnv.xmlString)"
"""#,
        ]

        if enableAddressSanitizer {
            components.append(#"enableAddressSanitizer = "YES""#)
        }
        if enableThreadSanitizer {
            components.append(#"enableThreadSanitizer = "YES""#)
        }
        if enableUBSanitizer {
            components.append(#"enableUBSanitizer = "YES""#)
        }

        let macroExpansion: String
        if let macroReference {
            macroExpansion = #"""
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "\#(macroReference.blueprintIdentifier)"
            BuildableName = "\#(macroReference.buildableName)"
            BlueprintName = "\#(macroReference.blueprintName)"
            ReferencedContainer = "\#(macroReference.referencedContainer)">
         </BuildableReference>
      </MacroExpansion>

"""#
        } else {
            macroExpansion = ""
        }

        return #"""
   <TestAction
      \#(components.joined(separator: "\n      "))>
\#(preActions.preActionsString)\#
\#(postActions.postActionsString)\#
\#(macroExpansion)\#
\#(commandLineArguments.commandLineArgumentsString)\#
\#(environmentVariables.environmentVariablesString)\#
      <Testables>
\#(testables.map(createTestableElement).joined())\#
      </Testables>
   </TestAction>
"""#
    }
}

public struct Testable {
    public let buildableReference: BuildableReference
    let skipped: Bool

    public init(
        buildableReference: BuildableReference,
        skipped: Bool
    ) {
        self.buildableReference = buildableReference
        self.skipped = skipped
    }
}

private func createTestableElement(_ testable: Testable) -> String {
    let reference = testable.buildableReference

    // 3 spaces for indentation is intentional
    return #"""
         <TestableReference
            skipped = "\#(testable.skipped.xmlString)">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "\#(reference.blueprintIdentifier)"
               BuildableName = "\#(reference.buildableName)"
               BlueprintName = "\#(reference.blueprintName)"
               ReferencedContainer = "\#(reference.referencedContainer)">
            </BuildableReference>
         </TestableReference>

"""#
}
