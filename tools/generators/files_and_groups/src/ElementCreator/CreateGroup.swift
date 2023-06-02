import PBXProj

extension ElementCreator {
    struct CreateGroup {
        private let createAttributes: CreateAttributes
        private let createIdentifier: CreateIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAttributes: CreateAttributes,
            createIdentifier: CreateIdentifier,
            callable: @escaping Callable
        ) {
            self.createAttributes = createAttributes
            self.createIdentifier = createIdentifier

            self.callable = callable
        }

        /// Creates a `PBXGroup` element.
        func callAsFunction(
            node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            childIdentifiers: [String]
        ) -> (
            element: Element,
            resolvedRepository: ResolvedRepository?
        ) {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*childIdentifiers:*/ childIdentifiers,
                /*createAttributes:*/ createAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateGroup.Callable

extension ElementCreator.CreateGroup {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ childIdentifiers: [String],
        _ createAttributes: ElementCreator.CreateAttributes,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    )

    static func defaultCallable(
        node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        childIdentifiers: [String],
        createAttributes: ElementCreator.CreateAttributes,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) {
        let bazelPath = parentBazelPath + node

        let attributes = createAttributes(
            name: node.name,
            bazelPath: bazelPath,
            isGroup: true,
            specialRootGroupType: specialRootGroupType
        )

        let nameAttribute: String
        if let name = attributes.elementAttributes.name {
            nameAttribute = #"""
			name = \#(name.pbxProjEscaped);

"""#
        } else {
            nameAttribute = ""
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
\#(nameAttribute)\#
			path = \#(attributes.elementAttributes.path.pbxProjEscaped);
			sourceTree = \#(attributes.elementAttributes.sourceTree.rawValue);
		}
"""#

        return (
            element: .init(
                identifier: createIdentifier(
                    path: bazelPath.path,
                    type: .group
                ),
                content: content,
                sortOrder: .groupLike
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }
}
