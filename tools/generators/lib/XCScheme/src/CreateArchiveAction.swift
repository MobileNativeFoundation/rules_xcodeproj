public struct CreateArchiveAction {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates an `ArchiveAction` element of an Xcode scheme.
    public func callAsFunction(buildConfiguration: String) -> String {
        return callable(/*buildConfiguration:*/ buildConfiguration)
    }
}

// MARK: - CreateArchiveAction.Callable

extension CreateArchiveAction {
    public typealias Callable = (_ buildConfiguration: String) -> String

    public static func defaultCallable(buildConfiguration: String) -> String {
        // 3 spaces for indentation is intentional
        return #"""
   <ArchiveAction
      buildConfiguration = "\#(buildConfiguration)"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
"""#
    }
}
