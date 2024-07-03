import PBXProj

extension ElementCreator {
    struct CreateInlineBazelGeneratedFilesElement {
        private let createIdentifier: CreateIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createIdentifier: CreateIdentifier,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createIdentifier = createIdentifier

            self.callable = callable
        }

        /// Creates a special root `PBXGroup` (i.e. "Bazel Generated" or "Bazel
        /// External Repositories").
        func callAsFunction(
            path: String,
            childIdentifiers: [String]
        ) -> Element {
            return callable(
                /*path:*/ path,
                /*childIdentifiers:*/ childIdentifiers,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateInlineBazelGeneratedFilesElement.Callable

extension ElementCreator.CreateInlineBazelGeneratedFilesElement {
    typealias Callable = (
        _ path: String,
        _ childIdentifiers: [String],
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element

    static func defaultCallable(
        path: String,
        childIdentifiers: [String],
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			name = "Bazel Generated";
			path = "\#(path)";
			sourceTree = SOURCE_ROOT;
		}
"""#

        return Element(
            name: "Bazel Generated",
            object: .init(
                identifier: createIdentifier(
                    path: path,
                    name: "Bazel Generated",
                    type: .group
                ),
                content: content
            ),
            sortOrder: .inlineBazelGenerated
        )
    }
}
