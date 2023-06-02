import PBXProj

extension ElementCreator {
    /// Creates a special root `PBXGroup` (i.e. "Bazel Generated" or "Bazel
    /// External Repositories").
    static func specialRootGroup(
        specialRootGroupType: SpecialRootGroupType,
        childIdentifiers: [String]
    ) -> Element {
        let identifier: String
        let name: String
        let path: String
        let sortOrder: Element.SortOrder
        switch specialRootGroupType {
        case .legacyBazelExternal, .siblingBazelExternal:
            identifier =
                Identifiers.FilesAndGroups.bazelExternalRepositoriesGroup
            name = "Bazel External Repositories"
            path = "../../external"
            sortOrder = .bazelExternalRepositories

        case .bazelGenerated:
            identifier = Identifiers.FilesAndGroups.bazelGeneratedFilesGroup
            name = "Bazel Generated Files"
            path = "bazel-out"
            sortOrder = .bazelGenerated
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXGroup;
			children = (
\#(childIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			name = \#(name.pbxProjEscaped);
			path = \#(path.pbxProjEscaped);
			sourceTree = SOURCE_ROOT;
		}
"""#

        return Element(
            identifier: identifier,
            content: content,
            sortOrder: sortOrder
        )
    }
}

enum SpecialRootGroupType {
    case bazelGenerated
    case legacyBazelExternal
    case siblingBazelExternal
}
