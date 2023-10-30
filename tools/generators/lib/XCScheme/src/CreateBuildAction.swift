public struct CreateBuildAction {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates a `BuildAction` element of an Xcode scheme.
    public func callAsFunction(
        entries: [BuildActionEntry],
        postActions: [ExecutionAction],
        preActions: [ExecutionAction]
    ) -> String {
        return callable(
            /*entries:*/ entries,
            /*postActions:*/ postActions,
            /*preActions:*/ preActions
        )
    }
}

public struct BuildActionEntry: Equatable {
    public struct BuildFor: OptionSet {
        public static let analyzing = Self(rawValue: 1 << 0)
        public static let testing = Self(rawValue: 1 << 1)
        public static let running = Self(rawValue: 1 << 2)
        public static let profiling = Self(rawValue: 1 << 3)
        public static let archiving = Self(rawValue: 1 << 4)

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public let buildableReference: BuildableReference
    public var buildFor: BuildFor

    public init(
        buildableReference: BuildableReference,
        buildFor: BuildFor
    ) {
        self.buildableReference = buildableReference
        self.buildFor = buildFor
    }
}

// MARK: - CreateBuildAction.Callable

extension CreateBuildAction {
    public typealias Callable = (
        _ entries: [BuildActionEntry],
        _ postActions: [ExecutionAction],
        _ preActions: [ExecutionAction]
    ) -> String

    public static func defaultCallable(
        entries: [BuildActionEntry],
        postActions: [ExecutionAction],
        preActions: [ExecutionAction]
    ) -> String {
        // 3 spaces for indentation is intentional
        return #"""
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "NO">
\#(preActions.preActionsString)\#
\#(postActions.postActionsString)\#
      <BuildActionEntries>
\#(entries.map(createBuildEntryElement).joined(separator: "\n"))
      </BuildActionEntries>
   </BuildAction>
"""#
    }
}

private func createBuildEntryElement(_ entry: BuildActionEntry) -> String {
    let buildFor = entry.buildFor
    let reference = entry.buildableReference

    // 3 spaces for indentation is intentional
    return #"""
         <BuildActionEntry
            buildForTesting = "\#(buildFor.contains(.testing).xmlString)"
            buildForRunning = "\#(buildFor.contains(.running).xmlString)"
            buildForProfiling = "\#(buildFor.contains(.profiling).xmlString)"
            buildForArchiving = "\#(buildFor.contains(.archiving).xmlString)"
            buildForAnalyzing = "\#(buildFor.contains(.analyzing).xmlString)">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "\#(reference.blueprintIdentifier)"
               BuildableName = "\#(reference.buildableName)"
               BlueprintName = "\#(reference.blueprintName)"
               ReferencedContainer = "\#(reference.referencedContainer)">
            </BuildableReference>
         </BuildActionEntry>
"""#
}
