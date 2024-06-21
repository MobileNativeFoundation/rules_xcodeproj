import PBXProj

extension ElementCreator {
    struct CreateSpecialRootGroupElement {
        private let createIdentifier: ElementCreator.CreateIdentifier
        
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(createIdentifier: CreateIdentifier, callable: @escaping Callable = Self.defaultCallable) {
            self.createIdentifier = createIdentifier
            self.callable = callable
        }

        /// Creates a special root `PBXGroup` (i.e. "Bazel Generated" or "Bazel
        /// External Repositories").
        func callAsFunction(
            specialRootGroupType: SpecialRootGroupType,
            childIdentifiers: [String],
            useRootStableIdentifiers: Bool,
            bazelPath: BazelPath
        ) -> Element {
            return callable(
                /*specialRootGroupType:*/ specialRootGroupType,
                /*childIdentifiers:*/ childIdentifiers,
                /*useRootStableIdentifiers:*/ useRootStableIdentifiers,
                /*createIdentifier:*/ createIdentifier,
                /*bazelPath:*/ bazelPath
            )
        }
    }
}

// MARK: - CreateSpecialRootGroup.Callable

extension ElementCreator.CreateSpecialRootGroupElement {
    typealias Callable = (
        _ specialRootGroupType: SpecialRootGroupType,
        _ childIdentifiers: [String],
        _ useRootStableIdentifiers: Bool,
        _ createIdentifier: ElementCreator.CreateIdentifier,
        _ bazelPath: BazelPath
    ) -> Element

    static func defaultCallable(
        specialRootGroupType: SpecialRootGroupType,
        childIdentifiers: [String],
        useRootStableIdentifiers: Bool,
        createIdentifier: ElementCreator.CreateIdentifier,
        bazelPath: BazelPath
    ) -> Element {
        let identifier: String = groupIdentifier(
            useStable: useRootStableIdentifiers,
            bazelPath: bazelPath, 
            type: specialRootGroupType,
            createIdentifier: createIdentifier
        )
        let name: String
        let path: String
        let sortOrder: Element.SortOrder
        switch specialRootGroupType {
        case .legacyBazelExternal, .siblingBazelExternal:
            name = "Bazel External Repositories"
            path = "../../external"
            sortOrder = .bazelExternalRepositories

        case .bazelGenerated:
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
    
    private static func groupIdentifier(
        useStable: Bool,
        bazelPath: BazelPath, 
        type: SpecialRootGroupType,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> String {
        if useStable {
            switch type {
            case .legacyBazelExternal, .siblingBazelExternal:
                return
                    Identifiers.FilesAndGroups.bazelExternalRepositoriesGroup

            case .bazelGenerated:
                return Identifiers.FilesAndGroups.bazelGeneratedFilesGroup
            }
        } else {
            return createIdentifier(path: bazelPath.path, name: bazelPath.path, type: .group)
        }
    }
}

enum SpecialRootGroupType {
    case bazelGenerated
    case legacyBazelExternal
    case siblingBazelExternal
}
