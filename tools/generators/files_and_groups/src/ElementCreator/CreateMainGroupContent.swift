import PBXProj

extension ElementCreator {
    struct CreateMainGroupContent {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the main `PBXGroup`.
        func callAsFunction(
            childIdentifiers: [String],
            indentWidth: UInt?,
            tabWidth: UInt?,
            usesTabs: Bool?,
            workspace: String
        ) -> String {
            return callable(
                /*childIdentifiers:*/ childIdentifiers,
                /*indentWidth:*/ indentWidth,
                /*tabWidth:*/ tabWidth,
                /*usesTabs:*/ usesTabs,
                /*workspace:*/ workspace
            )
        }
    }
}

// MARK: - CreateMainGroupContent.Callable

extension ElementCreator.CreateMainGroupContent {
    typealias Callable = (
        _ childIdentifiers: [String],
        _ indentWidth: UInt?,
        _ tabWidth: UInt?,
        _ usesTabs: Bool?,
        _ workspace: String
    ) -> String

    static func defaultCallable(
        childIdentifiers: [String],
        indentWidth: UInt?,
        tabWidth: UInt?,
        usesTabs: Bool?,
        workspace: String
    ) -> String {
        let indentWidthAttribute: String
        if let indentWidth {
            indentWidthAttribute = """
			indentWidth = \(indentWidth);

"""
        } else {
            indentWidthAttribute = ""
        }

        let tabWidthAttribute: String
        if let tabWidth {
            tabWidthAttribute = """
			tabWidth = \(tabWidth);

"""
        } else {
            tabWidthAttribute = ""
        }

        let usesTabsAttribute: String
        if let usesTabs {
            usesTabsAttribute = """
			usesTabs = \(usesTabs ? 1 : 0);

"""
        } else {
            usesTabsAttribute = ""
        }

        // The tabs for indenting are intentional
        return #"""
{
			isa = PBXGroup;
			children = (
\#(
    childIdentifiers
        .map { "\t\t\t\t\($0),\n" }
        .joined()
)\#
				\#(Identifiers.FilesAndGroups.productsGroup),
				\#(Identifiers.FilesAndGroups.frameworksGroup),
			);
\#(indentWidthAttribute)\#
			path = \#(workspace.pbxProjEscaped);
			sourceTree = "<absolute>";
\#(tabWidthAttribute)\#
\#(usesTabsAttribute)\#
		}
"""#
    }
}
