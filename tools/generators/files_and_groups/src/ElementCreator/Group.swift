import PBXProj

extension ElementCreator {
    /// Creates a `PBXGroup` element.
    static func group(
        node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        childIdentifiers: [String],
        createAttributes: Environment.CreateAttributes,
        createIdentifier: Environment.CreateIdentifier
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) {
        let bazelPath = parentBazelPath + node

        let attributes = createAttributes(
            /*name:*/ node.name,
            /*bazelPath:*/ bazelPath,
            /*isGroup:*/ true,
            /*specialRootGroupType:*/ specialRootGroupType
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
                    bazelPath.path,
                    /*type:*/ .group
                ),
                content: content,
                sortOrder: .groupLike
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }
}
