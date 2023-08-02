import PBXProj

extension ElementCreator {
    struct CreateVariantGroup {
        private let createVariantGroupElement: CreateVariantGroupElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createVariantGroupElement: CreateVariantGroupElement,
            callable: @escaping Callable
        ) {
            self.createVariantGroupElement = createVariantGroupElement

            self.callable = callable
        }

        /// Creates a grouping of localizations for a file. Xcode calls these
        /// "variant groups". The name will be the filename that has one or
        /// more localizations. For example, the variant group "Foo.xib" will
        /// have children like "Base.lproj/Foo.xib" and "en.lproj/Foo.strings".
        func callAsFunction(
            name: String,
            parentBazelPath: BazelPath,
            localizedFiles: [GroupChild.LocalizedFile]
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*name:*/ name,
                /*parentBazelPath:*/ parentBazelPath,
                /*localizedFiles:*/ localizedFiles,
                /*createVariantGroupElement:*/ createVariantGroupElement
            )
        }
    }
}

// MARK: - CreateVariantGroup.Callable

extension ElementCreator.CreateVariantGroup {
    typealias Callable = (
        _ name: String,
        _ parentBazelPath: BazelPath,
        _ localizedFiles: [GroupChild.LocalizedFile],
        _ createVariantGroupElement: ElementCreator.CreateVariantGroupElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        name: String,
        parentBazelPath: BazelPath,
        localizedFiles: [GroupChild.LocalizedFile],
        createVariantGroupElement: ElementCreator.CreateVariantGroupElement
    ) -> GroupChild.ElementAndChildren {
        let group = createVariantGroupElement(
            name: name,
            path: "\(parentBazelPath.path)/\(name)",
            childIdentifiers: localizedFiles.map(\.element.object.identifier)
        )

        let bazelPathAndIdentifiers = localizedFiles
            .flatMap { $0.bazelPaths }
            .map { ($0, group.object.identifier) }

        var transitiveObjects = localizedFiles.map(\.element.object)
        transitiveObjects.append(group.object)

        let regions = Set(localizedFiles.map(\.region))

        return GroupChild.ElementAndChildren(
            element: group,
            transitiveObjects: transitiveObjects,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: regions,
            resolvedRepositories: []
        )
    }
}
