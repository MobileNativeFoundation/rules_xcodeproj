import PBXProj

extension ElementCreator {
    struct CreateExternalRepositoriesGroupElement {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a "Bazel External Repositories" `PBXGroup`.
        func callAsFunction(childIdentifiers: [String]) -> Element {
            return callable(/*childIdentifiers:*/ childIdentifiers)
        }
    }
}

// MARK: - CreateExternalRepositoriesGroupElement.Callable

extension ElementCreator.CreateExternalRepositoriesGroupElement {
    typealias Callable = (_ childIdentifiers: [String]) -> Element

    static func defaultCallable(childIdentifiers: [String]) -> Element {
        let name = "Bazel External Repositories"

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			name = \#(name.pbxProjEscaped);
			path = ../../external;
			sourceTree = SOURCE_ROOT;
		}
"""#

        return Element(
            name: name,
            object: .init(
                identifier:
                    Identifiers.FilesAndGroups.bazelExternalRepositoriesGroup,
                content: content
            ),
            sortOrder: .bazelExternalRepositories
        )
    }
}
