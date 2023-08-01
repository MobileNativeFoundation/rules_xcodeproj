import PBXProj

extension ElementCreator {
    struct CreateSpecialRootGroupElement {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a special root `PBXGroup` (i.e. "Bazel Generated" or "Bazel
        /// External Repositories").
        func callAsFunction(
            specialRootGroupType: SpecialRootGroupType,
            childIdentifiers: [String]
        ) -> Element {
            return callable(
                /*specialRootGroupType:*/ specialRootGroupType,
                /*childIdentifiers:*/ childIdentifiers
            )
        }
    }
}

// MARK: - CreateSpecialRootGroup.Callable

extension ElementCreator.CreateSpecialRootGroupElement {
    typealias Callable = (
        _ specialRootGroupType: SpecialRootGroupType,
        _ childIdentifiers: [String]
    ) -> Element

    static func defaultCallable(
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
            name: name,
            object: .init(
                identifier: identifier,
                content: content
            ),
            sortOrder: sortOrder
        )
    }
}

enum SpecialRootGroupType {
    case bazelGenerated
    case legacyBazelExternal
    case siblingBazelExternal
}
