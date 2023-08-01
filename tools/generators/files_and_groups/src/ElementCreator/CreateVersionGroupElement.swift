import PBXProj

extension ElementCreator {
    struct CreateVersionGroupElement {
        private let createAttributes: CreateAttributes

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAttributes: CreateAttributes,
            callable: @escaping Callable
        ) {
            self.createAttributes = createAttributes
            self.callable = callable
        }

        /// Creates an `XCVersionGroup` element.
        func callAsFunction(
            name: String,
            bazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            identifier: String,
            childIdentifiers: [String],
            selectedChildIdentifier: String?
        ) -> (
            element: Element,
            resolvedRepository: ResolvedRepository?
        ) {
            return callable(
                /*name:*/ name,
                /*bazelPath:*/ bazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*identifier:*/ identifier,
                /*childIdentifiers:*/ childIdentifiers,
                /*selectedChildIdentifier:*/ selectedChildIdentifier,
                /*createAttributes:*/ createAttributes
            )
        }
    }
}

// MARK: - CreateVersionGroupElement.Callable

extension ElementCreator.CreateVersionGroupElement {
    typealias Callable = (
        _ name: String,
        _ bazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ identifier: String,
        _ childIdentifiers: [String],
        _ selectedChildIdentifier: String?,
        _ createAttributes: ElementCreator.CreateAttributes
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    )

    static func defaultCallable(
        name: String,
        bazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        identifier: String,
        childIdentifiers: [String],
        selectedChildIdentifier: String?,
        createAttributes: ElementCreator.CreateAttributes
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) {
        let attributes = createAttributes(
            name: name,
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

        let currentVersionAttribute: String
        if let selectedChildIdentifier {
            currentVersionAttribute = #"""
			currentVersion = \#(selectedChildIdentifier);

"""#
        } else {
            currentVersionAttribute = ""
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = XCVersionGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
\#(currentVersionAttribute)\#
\#(nameAttribute)\#
			path = \#(attributes.elementAttributes.path.pbxProjEscaped);
			sourceTree = \#(attributes.elementAttributes.sourceTree.rawValue);
			versionGroupType = wrapper.xcdatamodel;
		}
"""#

        return (
            element: .init(
                name: name,
                object: .init(
                    identifier: identifier,
                    content: content
                ),
                sortOrder: .fileLike
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }
}
