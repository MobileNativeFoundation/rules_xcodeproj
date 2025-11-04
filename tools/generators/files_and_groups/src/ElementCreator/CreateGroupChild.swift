import PBXProj

extension ElementCreator {
    struct CreateGroupChild {
        private let createFile: CreateFile
        private let createGroup: CreateGroup
        private let createInlineBazelGeneratedFiles:
            ElementCreator.CreateInlineBazelGeneratedFiles
        private let createLocalizedFiles: CreateLocalizedFiles
        private let createVersionGroup: CreateVersionGroup

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createFile: CreateFile,
            createGroup: CreateGroup,
            createInlineBazelGeneratedFiles:
                ElementCreator.CreateInlineBazelGeneratedFiles,
            createLocalizedFiles: CreateLocalizedFiles,
            createVersionGroup: CreateVersionGroup,
            callable: @escaping Callable
        ) {
            self.createFile = createFile
            self.createGroup = createGroup
            self.createInlineBazelGeneratedFiles =
                createInlineBazelGeneratedFiles
            self.createLocalizedFiles = createLocalizedFiles
            self.createVersionGroup = createVersionGroup
            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            parentBazelPathType: BazelPathType
        ) -> GroupChild {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*parentBazelPathType:*/ parentBazelPathType,
                /*createFile:*/ createFile,
                /*createGroup:*/ createGroup,
                /*createGroupChild:*/ self,
                /*createInlineBazelGeneratedFiles:*/
                    createInlineBazelGeneratedFiles,
                /*createLocalizedFiles:*/ createLocalizedFiles,
                /*createVersionGroup:*/ createVersionGroup
            )
        }
    }
}

// MARK: - CreateGroupChild.Callable

extension ElementCreator.CreateGroupChild {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ parentBazelPathType: BazelPathType,
        _ createFile: ElementCreator.CreateFile,
        _ createGroup: ElementCreator.CreateGroup,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createInlineBazelGeneratedFiles:
            ElementCreator.CreateInlineBazelGeneratedFiles,
        _ createLocalizedFiles: ElementCreator.CreateLocalizedFiles,
        _ createVersionGroup: ElementCreator.CreateVersionGroup
    ) -> GroupChild

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        parentBazelPathType: BazelPathType,
        createFile: ElementCreator.CreateFile,
        createGroup: ElementCreator.CreateGroup,
        createGroupChild: ElementCreator.CreateGroupChild,
        createInlineBazelGeneratedFiles:
            ElementCreator.CreateInlineBazelGeneratedFiles,
        createLocalizedFiles: ElementCreator.CreateLocalizedFiles,
        createVersionGroup: ElementCreator.CreateVersionGroup
    ) -> GroupChild {
        switch node {
        case .group(let name, let children):
            let (basenameWithoutExt, ext) = name.splitExtension()
            switch ext {
            case "lproj":
                return .localizedRegion(
                    createLocalizedFiles(
                        name: name,
                        nodeChildren: children,
                        parentBazelPath: parentBazelPath,
                        region: basenameWithoutExt
                    )
                )

            case "xcdatamodeld":
                return .elementAndChildren(
                    createVersionGroup(
                        name: name,
                        nodeChildren: children,
                        parentBazelPath: parentBazelPath,
                        bazelPathType: parentBazelPathType
                    )
                )

            case "xcmappingmodel":
                return .elementAndChildren(
                    createFile(
                        name: name,
                        bazelPath: BazelPath(
                            parent: parentBazelPath,
                            path: name
                        ),
                        bazelPathType: parentBazelPathType,
                        transitiveBazelPaths: []
                    )
                )

            default:
                return .elementAndChildren(
                    createGroup(
                        name: name,
                        nodeChildren: children,
                        parentBazelPath: parentBazelPath,
                        bazelPathType: parentBazelPathType,
                        createGroupChild: createGroupChild
                    )
                )
            }

        case .file(let name):
            return .elementAndChildren(
                createFile(
                    name: name,
                    bazelPath: BazelPath(
                        parent: parentBazelPath,
                        path: name
                    ),
                    bazelPathType: parentBazelPathType,
                    transitiveBazelPaths: []
                )
            )

        case .generatedFiles(let generatedFiles):
            return .elementAndChildren(
                createInlineBazelGeneratedFiles(
                    for: generatedFiles,
                    createGroupChild: createGroupChild
                )
            )
        }
    }
}

struct Element: Equatable {
    enum SortOrder: Comparable {
        case groupLike
        case inlineBazelGenerated
        case fileLike
        case bazelExternalRepositories
        case rulesXcodeprojInternal
    }

    let name: String
    let object: Object
    let sortOrder: SortOrder
}

enum GroupChild: Equatable {
    struct ElementAndChildren {
        let element: Element
        let transitiveObjects: [Object]
        let bazelPathAndIdentifiers: [(BazelPath, String)]
        let knownRegions: Set<String>
        let resolvedRepositories: [ResolvedRepository]
    }

    struct LocalizedFile: Equatable {
        let element: Element
        let region: String
        let name: String
        let basenameWithoutExt: String
        let ext: String?
        let bazelPaths: [BazelPath]
    }

    case elementAndChildren(ElementAndChildren)
    case localizedRegion([LocalizedFile])
}

extension GroupChild.ElementAndChildren {
    init(
        bazelPath: BazelPath,
        element: Element,
        resolvedRepository: ResolvedRepository?,
        children: [GroupChild.ElementAndChildren]
    ) {
        var bazelPathAndIdentifiers: [(BazelPath, String)] = []
        var knownRegions: Set<String> = []
        var resolvedRepositories: [ResolvedRepository] = []
        var transitiveObjects: [Object] = []
        for child in children {
            bazelPathAndIdentifiers
                .append(contentsOf: child.bazelPathAndIdentifiers)
            knownRegions.formUnion(child.knownRegions)
            resolvedRepositories.append(contentsOf: child.resolvedRepositories)
            transitiveObjects.append(contentsOf: child.transitiveObjects)
        }

        bazelPathAndIdentifiers.append((bazelPath, element.object.identifier))
        transitiveObjects.append(element.object)

        if let resolvedRepository {
            resolvedRepositories.append(resolvedRepository)
        }

        self.init(
            element: element,
            transitiveObjects: transitiveObjects,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }

    init(
        bazelPath: BazelPath,
        element: Element,
        includeParentInBazelPathAndIdentifiers: Bool = true,
        resolvedRepository: ResolvedRepository?,
        children: GroupChildElements
    ) {
        var bazelPathAndIdentifiers = children.bazelPathAndIdentifiers
        if includeParentInBazelPathAndIdentifiers {
            bazelPathAndIdentifiers.append((bazelPath, element.object.identifier))
        }

        var transitiveObjects = children.transitiveObjects
        transitiveObjects.append(element.object)

        var resolvedRepositories = children.resolvedRepositories
        if let resolvedRepository {
            resolvedRepositories.append(resolvedRepository)
        }

        self.init(
            element: element,
            transitiveObjects: transitiveObjects,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: children.knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }
}

extension GroupChild.ElementAndChildren: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.bazelPathAndIdentifiers.count ==
            rhs.bazelPathAndIdentifiers.count
        else {
            return false
        }

        for (lhsPair, rhsPair) in zip(
            lhs.bazelPathAndIdentifiers,
            rhs.bazelPathAndIdentifiers
        ) {
            guard lhsPair == rhsPair else {
                return false
            }
        }

        return (
            lhs.element,
            lhs.transitiveObjects,
            lhs.knownRegions,
            lhs.resolvedRepositories
        ) == (
            rhs.element,
            rhs.transitiveObjects,
            rhs.knownRegions,
            rhs.resolvedRepositories
        )
    }
}
