import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

struct ExecutionActionsArguments: ParsableArguments {
    @Option(
        parsing: .upToNextOption,
        help: "Scheme name for all of the execution actions."
    )
    var executionActions: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Title for all of the execution actions. There must be as many titles as there \
are execution actions.
"""
    )
    var executionActionTitle: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Whether the execution action is pre action. There must be as many bools as \
there are execution actions.
"""
    )
    var executionActionIsPreAction: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Script text for all of the execution actions. There must be as many script \
texts as there are execution actions.
"""
    )
    var executionActionScriptText: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The action (i.e. 'test', 'run', or 'profile') all execution actions are \
associated with. This cannot be 'build', use <execution-action-is-for-build> \
for that, and set the action that <execution-action-target> is associated \
with. There must be as many values as there are execution actions.
"""
    )
    var executionActionAction: [ExecutionActionAction] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Whether the execution action is to be included in the Build action. If not, it \
will be included in the <execution-action-action>. There must be as many bools \
as there are execution actions.
"""
    )
    var executionActionIsForBuild: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID all execution actions are associated with. There must be as many \
target IDs as there are execution actions.
"""
    )
    var executionActionTarget: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The order within an action the execution action should be placed. Use an empty \
string for an unspecified order. There must be as many integers as there are \
execution actions.
"""
    )
    var executionActionOrder: [Int?] = []

    // MARK: Validation

    mutating func validate() throws {
        guard executionActionTitle.count == executionActions.count else {
            throw ValidationError("""
<execution-action-title> (\(executionActionTitle.count) elements) must have \
exactly as many elements as <execution-actions> (\(executionActions.count) \
elements).
""")
        }

        guard executionActionScriptText.count == executionActions.count else {
            throw ValidationError("""
<execution-action-script-text> (\(executionActionScriptText.count) elements) \
must have exactly as many elements as <execution-actions> \
(\(executionActions.count) elements).
""")
        }

        guard executionActionAction.count == executionActions.count else {
            throw ValidationError("""
<execution-action-action> (\(executionActionAction.count) elements) must have \
exactly as many elements as <execution-actions> (\(executionActions.count) \
elements).
""")
        }

        guard executionActionIsForBuild.count == executionActions.count else {
            throw ValidationError("""
<execution-action-is-for-build> (\(executionActionIsForBuild.count) elements) \
must have exactly as many elements as <execution-actions> \
(\(executionActions.count) elements).
""")
        }

        guard executionActionTarget.count == executionActions.count else {
            throw ValidationError("""
<execution-action-target> (\(executionActionTarget.count) elements) must have \
exactly as many elements as <execution-actions> (\(executionActions.count) \
elements).
""")
        }

        guard executionActionOrder.count == executionActions.count else {
            throw ValidationError("""
<execution-action-order> (\(executionActionOrder.count) elements) must have \
exactly as many elements as <execution-actions> (\(executionActions.count) \
elements).
""")
        }
    }
}

// MARK: - ExecutionActions

enum ExecutionActionAction: String, ExpressibleByArgument {
    case test
    case run
    case profile
}

extension ExecutionActionsArguments {
    /// Maps scheme name -> action -> target ID -> `isPreAction` ->
    /// `ExecutionActions`.
    func calculateExecutionActions() -> [
        String: [
            ExecutionActionAction: [
                TargetID: [Bool: [SchemeInfo.ExecutionAction]]
            ]
        ]
    ] {
        var ret: [
            String: [
                ExecutionActionAction: [
                    TargetID: [Bool: [SchemeInfo.ExecutionAction]]
                ]
            ]
        ] = [:]

        for executionActionIndex in executionActions.indices {
            ret[
                executionActions[executionActionIndex],
                default: [:]
            ][
                executionActionAction[executionActionIndex],
                default: [:]
            ][
                executionActionTarget[executionActionIndex],
                default: [:]
            ][
                executionActionIsPreAction[executionActionIndex],
                default: []
            ].append(
                .init(
                    title: executionActionTitle[executionActionIndex],
                    scriptText:
                        executionActionScriptText[executionActionIndex],
                    forBuild: executionActionIsForBuild[executionActionIndex],
                    order: executionActionOrder[executionActionIndex]
                )
            )
        }

        return ret
    }
}
