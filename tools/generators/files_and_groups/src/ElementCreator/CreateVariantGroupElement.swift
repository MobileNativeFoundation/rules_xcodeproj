import PBXProj

extension ElementCreator {
    struct CreateVariantGroupElement {
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

        /// Creates a `PBXVariantGroup` element.
        func callAsFunction(
            name: String,
            path: String,
            childIdentifiers: [String]
        ) -> Element {
            return callable(
                /*name:*/ name,
                /*path:*/ path,
                /*childIdentifiers:*/ childIdentifiers,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateVariantGroup.Callable

extension ElementCreator.CreateVariantGroupElement {
    typealias Callable = (
        _ name: String,
        _ path: String,
        _ childIdentifiers: [String],
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element

    static func defaultCallable(
        name: String,
        path: String,
        childIdentifiers: [String],
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXVariantGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			name = \#(name.pbxProjEscaped);
			sourceTree = "<group>";
		}
"""#

        return Element(
            name: name,
            object: .init(
                identifier: createIdentifier(
                    path: path,
                    type: .localized
                ),
                content: content
            ),
            sortOrder: .fileLike
        )
    }
}
