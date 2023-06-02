import PBXProj

extension ElementCreator {
    /// Creates a `PBXVariantGroup` element.
    static func variantGroup(
        name: String,
        bazelPathStr: String,
        sourceTree: SourceTree,
        childIdentifiers: [String],
        createIdentifier: CreateIdentifier
    ) -> Element {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXVariantGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			name = \#(name.pbxProjEscaped);
			sourceTree = \#(sourceTree.rawValue);
		}
"""#

        return Element(
            identifier: createIdentifier(
                path: bazelPathStr,
                type: .localized
            ),
            content: content,
            sortOrder: .fileLike
        )
    }
}
