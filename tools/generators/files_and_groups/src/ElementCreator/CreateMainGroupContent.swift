import PBXProj

extension ElementCreator {
    struct CreateMainGroupContent {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the main `PBXGroup`.
        func callAsFunction(
            childIdentifiers: [String],
            workspace: String
        ) -> String {
            return callable(
                /*childIdentifiers:*/ childIdentifiers,
                /*workspace:*/ workspace
            )
        }
    }
}

// MARK: - CreateMainGroupContent.Callable

extension ElementCreator.CreateMainGroupContent {
    typealias Callable = (
        _ childIdentifiers: [String],
        _ workspace: String
    ) -> String

    static func defaultCallable(
        childIdentifiers: [String],
        workspace: String
    ) -> String {
        // The tabs for indenting are intentional
        return #"""
{
			isa = PBXGroup;
			children = (
\#(
    childIdentifiers
        .map { "\t\t\t\t\($0),\n" }
        .joined()
)\#
				\#(Identifiers.FilesAndGroups.productsGroup),
				\#(Identifiers.FilesAndGroups.frameworksGroup),
			);
			path = \#(workspace.pbxProjEscaped);
			sourceTree = "<absolute>";
		}
"""#
    }
}
