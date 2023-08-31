public struct ExecutionAction {
    let title: String
    let escapedScriptText: String
    let macroReference: BuildableReference?

    public init(
        title: String,
        escapedScriptText: String,
        expandVariablesBasedOn macroReference: BuildableReference?
    ) {
        self.title = title
        self.escapedScriptText = escapedScriptText
        self.macroReference = macroReference
    }
}

extension Array where Element == ExecutionAction {
    // This isn't a full `callAsFunction()` type because we don't test it
    // directly, but we reuse the logic in 3 elements.
    var postActionsString: String {
        guard !isEmpty else {
            return ""
        }

        return #"""
      <PostActions>
\#(map(createExecutionActionElement).joined(separator: "\n"))
      </PostActions>

"""#
    }

    // This isn't a full `callAsFunction()` type because we don't test it
    // directly, but we reuse the logic in 3 elements.
    var preActionsString: String {
        guard !isEmpty else {
            return ""
        }

        return #"""
      <PreActions>
\#(map(createExecutionActionElement).joined(separator: "\n"))
      </PreActions>

"""#
    }
}

private func createExecutionActionElement(
    _ executionAction: ExecutionAction
) -> String {
    let buildable: String
    if let reference = executionAction.macroReference {
        buildable = #"""
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "\#(reference.blueprintIdentifier)"
                     BuildableName = "\#(reference.buildableName)"
                     BlueprintName = "\#(reference.blueprintName)"
                     ReferencedContainer = "\#(reference.referencedContainer)">
                  </BuildableReference>
               </EnvironmentBuildable>

"""#
    } else {
        buildable = ""
    }

    return #"""
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "\#(executionAction.title.schemeXmlEscaped)"
               scriptText = "\#(executionAction.escapedScriptText)">
\#(buildable)\#
            </ActionContent>
         </ExecutionAction>
"""#
}
