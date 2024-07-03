import PBXProj

extension ElementCreator {
    struct CreateInlineBazelGeneratedConfigGroupElement {
        private let createIdentifier: CreateIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createIdentifier: CreateIdentifier,
            callable: @escaping Callable
        ) {
            self.createIdentifier = createIdentifier

            self.callable = callable
        }

        /// Creates a `PBXGroup` element for an inline Bazel Generated Files
        /// config.
        func callAsFunction(
            name: String,
            path: String,
            bazelPath: BazelPath,
            childIdentifiers: [String]
        ) -> Element {
            return callable(
                /*name:*/ name,
                /*path:*/ path,
                /*bazelPath:*/ bazelPath,
                /*childIdentifiers:*/ childIdentifiers,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateInlineBazelGeneratedConfigGroupElement.Callable

extension ElementCreator.CreateInlineBazelGeneratedConfigGroupElement {
    typealias Callable = (
        _ name: String,
        _ path: String,
        _ bazelPath: BazelPath,
        _ childIdentifiers: [String],
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element

    static func defaultCallable(
        name: String,
        path: String,
        bazelPath: BazelPath,
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
			name = \#(name.pbxProjEscaped);
			path = \#(path.pbxProjEscaped);
			sourceTree = "<group>";
		}
"""#

        return .init(
            name: name,
            object: .init(
                identifier: createIdentifier(
                    path: bazelPath.path,
                    name: name,
                    type: .group
                ),
                content: content
            ),
            sortOrder: .groupLike
        )
    }
}
