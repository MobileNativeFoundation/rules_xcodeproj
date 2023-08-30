import PBXProj

extension Generator {
    /// Calculates the files and groups `PBXProj` partial.
    static func filesAndGroupsPartial(
        buildFilesPartial: String,
        elementsPartial: String
    ) -> String {
        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
\#(elementsPartial)\#
\#(buildFilesPartial)\#
		\#(Identifiers.FilesAndGroups.frameworksGroup) = {
			isa = PBXGroup;
			children = (
			);
			name = Frameworks;
			sourceTree = "<group>";
		};
	};
	rootObject = \#(Identifiers.Project.id);
}

"""#
    }
}
