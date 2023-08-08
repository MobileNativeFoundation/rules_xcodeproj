import PBXProj

extension ElementCreator {
    struct CreateInternalGroup {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable) {
            self.callable = callable
        }

        /// Creates the `PBXGroup` element for the internal group (i.e.
        /// `rules_xcodeproj`).
        func callAsFunction(installPath: String) -> GroupChild {
            return callable(/*installPath:*/ installPath)
        }
    }
}

// MARK: - CreateInternalGroup.Callable

extension ElementCreator.CreateInternalGroup {
    typealias Callable = (_ installPath: String) -> GroupChild

    private static let compileStubObject = Object(
        identifier: Identifiers.FilesAndGroups.compileStub,
        content: #"""
{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = _CompileStub_.m; sourceTree = DERIVED_FILE_DIR; }
"""#
    )

    static func defaultCallable(installPath: String) -> GroupChild {
        let group = Element(
            name: "rules_xcodeproj",
            object: .init(
                identifier: Identifiers.FilesAndGroups.rulesXcodeprojInternalGroup,
                content: #"""
{
			isa = PBXGroup;
			children = (
				\#(compileStubObject.identifier),
			);
			name = rules_xcodeproj;
			path = \#("\(installPath)/rules_xcodeproj".pbxProjEscaped);
			sourceTree = "<group>";
		}
"""#
            ),
            sortOrder: .rulesXcodeprojInternal
        )

        return .elementAndChildren(
            .init(
                element: group,
                transitiveObjects: [compileStubObject, group.object],
                bazelPathAndIdentifiers: [
                    (BazelPath(""), compileStubObject.identifier),
                ],
                knownRegions: [],
                resolvedRepositories: []
            )
        )
    }
}
