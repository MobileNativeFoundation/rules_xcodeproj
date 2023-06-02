import PBXProj

extension ElementCreator {
    /// Creates the main `PBXGroup`.
    static func mainGroup(
        // FIXME: Take pre-sorted identifiers instead
        rootElements: [Element],
        workspace: String
    ) -> String {
        // The tabs for indenting are intentional
        return #"""
{
			isa = PBXGroup;
			children = (
\#(
    rootElements
        .map { "\t\t\t\t\($0.identifier),\n" }
        .joined()
)\#
			);
			path = \#(workspace.pbxProjEscaped);
			sourceTree = "<absolute>";
		}
"""#
    }
}
