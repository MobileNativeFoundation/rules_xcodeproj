import PBXProj

extension ElementCreator {
    struct CalculatePartial {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the elements partial.
        func callAsFunction(
            objects: [Object],
            mainGroup: String,
            workspace: String
        ) -> String {
            return callable(
                /*objects:*/ objects,
                /*mainGroup:*/ mainGroup,
                /*workspace:*/ workspace
            )
        }
    }
}

// MARK: - CalculatePartial.Callable

extension ElementCreator.CalculatePartial {
    typealias Callable = (
        _ objects: [Object],
        _ mainGroup: String,
        _ workspace: String
    ) -> String

    static func defaultCallable(
        objects: [Object],
        mainGroup: String,
        workspace: String
    ) -> String {
        // The tabs for indenting are intentional
        return #"""
		\#(Identifiers.FilesAndGroups.mainGroup(workspace)) = \#(mainGroup);\#
\#(objects.map { "\n\t\t\($0.identifier) = \($0.content);" }.joined())

"""#
    }
}
