import PBXProj

extension ElementCreator {
    /// Creates an `XCVersionGroup` element.
    static func versionGroup(
        node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        childIdentifiers: [String],
        selectedChildIdentifier: String,
        createAttributes: CreateAttributes,
        createIdentifier: CreateIdentifier
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
			isa = XCVersionGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			currentVersion = \#(selectedChildIdentifier);
\#(nameAttribute)\#
			path = \#(attributes.elementAttributes.path.pbxProjEscaped);
			sourceTree = \#(attributes.elementAttributes.sourceTree.rawValue);
			versionGroupType = wrapper.xcdatamodel;
		}
"""#

        return (
            element: .init(
                identifier: createIdentifier(
                    path: bazelPath.path,
                    type: .coreData
                ),
                content: content,
                sortOrder: .fileLike
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }
}
