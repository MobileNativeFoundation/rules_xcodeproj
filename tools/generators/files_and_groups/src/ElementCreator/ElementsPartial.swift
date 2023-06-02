import PBXProj

extension ElementCreator {
    static func partial(
        elements: [Element],
        mainGroup: String,
        workspace: String
    ) -> String {
        // The tabs for indenting are intentional
        return #"""
		\#(Identifiers.FilesAndGroups.mainGroup(workspace)) = \#(mainGroup);\#
\#(elements.map { "\n\t\t\($0.identifier) = \($0.content);" }.joined())

"""#
    }
}
