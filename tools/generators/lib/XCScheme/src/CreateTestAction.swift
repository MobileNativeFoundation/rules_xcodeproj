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
        appLanguage: String?,
        appRegion: String?,
        codeCoverage: Bool,
        buildConfiguration: String,
        commandLineArguments: [CommandLineArgument],
        enableAddressSanitizer: Bool,
        enableThreadSanitizer: Bool,
        enableUBSanitizer: Bool,
        enableMainThreadChecker: Bool,
        enableThreadPerformanceChecker: Bool,
        environmentVariables: [EnvironmentVariable],
        expandVariablesBasedOn: BuildableReference?,
        postActions: [ExecutionAction],
        preActions: [ExecutionAction],
        testables: [Testable],
        useLaunchSchemeArgsEnv: Bool
    ) -> String {
        return callable(
            /*appLanguage:*/ appLanguage,
            /*appRegion:*/ appRegion,
            /*codeCoverage:*/ codeCoverage,
            /*buildConfiguration:*/ buildConfiguration,
            /*commandLineArguments:*/ commandLineArguments,
            /*enableAddressSanitizer:*/ enableAddressSanitizer,
            /*enableThreadSanitizer:*/ enableThreadSanitizer,
            /*enableUBSanitizer:*/ enableUBSanitizer,
            /*enableMainThreadChecker:*/ enableMainThreadChecker,
            /*enableThreadPerformanceChecker:*/ enableThreadPerformanceChecker,
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
        _ appLanguage: String?,
        _ appRegion: String?,
        _ codeCoverage: Bool,
        _ buildConfiguration: String,
        _ commandLineArguments: [CommandLineArgument],
        _ enableAddressSanitizer: Bool,
        _ enableThreadSanitizer: Bool,
        _ enableUBSanitizer: Bool,
        _ enableMainThreadChecker: Bool,
        _ enableThreadPerformanceChecker: Bool,
        _ environmentVariables: [EnvironmentVariable],
        _ expandVariablesBasedOn: BuildableReference?,
        _ postActions: [ExecutionAction],
        _ preActions: [ExecutionAction],
        _ testables: [Testable],
        _ useLaunchSchemeArgsEnv: Bool
    ) -> String

    public static func defaultCallable(
        appLanguage: String?,
        appRegion: String?,
        codeCoverage: Bool,
        buildConfiguration: String,
        commandLineArguments: [CommandLineArgument],
        enableAddressSanitizer: Bool,
        enableThreadSanitizer: Bool,
        enableUBSanitizer: Bool,
        enableMainThreadChecker: Bool,
        enableThreadPerformanceChecker: Bool,
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

        if !enableMainThreadChecker {
            components.append(#"disableMainThreadChecker = "YES""#)
        }
        if !enableThreadPerformanceChecker {
            components.append(#"disablePerformanceAntipatternChecker = "YES""#)
        }

        if let appLanguage {
            components.append("language = \"\(appLanguage)\"")
        }
        if let appRegion {
            components.append("region = \"\(appRegion)\"")
        }
        if codeCoverage {
            components.append("codeCoverageEnabled = \"YES\"")
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
    let isSkipped: Bool

    public init(
        buildableReference: BuildableReference,
        isSkipped: Bool
    ) {
        self.buildableReference = buildableReference
        self.isSkipped = isSkipped
    }
}

private func createTestableElement(_ testable: Testable) -> String {
    let reference = testable.buildableReference

    // 3 spaces for indentation is intentional
    return #"""
         <TestableReference
            skipped = "\#(testable.isSkipped.xmlString)">
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
