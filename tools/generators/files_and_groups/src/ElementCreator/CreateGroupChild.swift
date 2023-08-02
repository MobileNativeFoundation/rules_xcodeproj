import PBXProj

extension ElementCreator {
    struct CreateGroupChild {
        private let createFile: CreateFile
        private let createGroup: CreateGroup
        private let createLocalizedFiles: CreateLocalizedFiles
        private let createVersionGroup: CreateVersionGroup

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createFile: CreateFile,
            createGroup: CreateGroup,
            createLocalizedFiles: CreateLocalizedFiles,
            createVersionGroup: CreateVersionGroup,
            callable: @escaping Callable
        ) {
            self.createFile = createFile
            self.createGroup = createGroup
            self.createLocalizedFiles = createLocalizedFiles
            self.createVersionGroup = createVersionGroup
            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?
        ) -> GroupChild {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createFile:*/ createFile,
                /*createGroup:*/ createGroup,
                /*createGroupChild:*/ self,
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
        _ specialRootGroupType: SpecialRootGroupType?,
        _ createFile: ElementCreator.CreateFile,
        _ createGroup: ElementCreator.CreateGroup,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createLocalizedFiles: ElementCreator.CreateLocalizedFiles,
        _ createVersionGroup: ElementCreator.CreateVersionGroup
    ) -> GroupChild

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createFile: ElementCreator.CreateFile,
        createGroup: ElementCreator.CreateGroup,
        createGroupChild: ElementCreator.CreateGroupChild,
        createLocalizedFiles: ElementCreator.CreateLocalizedFiles,
        createVersionGroup: ElementCreator.CreateVersionGroup
    ) -> GroupChild {
        guard !node.children.isEmpty else {
            // File
            return .elementAndChildren(
                createFile(
                    for: node,
                    bazelPath: parentBazelPath + node,
                    specialRootGroupType: specialRootGroupType
                )
            )
        }

        // Group
        let (basenameWithoutExt, ext) = node.splitExtension()
        switch ext {
        case "lproj":
            return .localizedRegion(
                createLocalizedFiles(
                    for: node,
                    parentBazelPath: parentBazelPath,
                    specialRootGroupType: specialRootGroupType,
                    region: basenameWithoutExt
                )
            )

        case "xcdatamodeld":
            return .elementAndChildren(
                createVersionGroup(
                    for: node,
                    parentBazelPath: parentBazelPath,
                    specialRootGroupType: specialRootGroupType
                )
            )

        default:
            return .elementAndChildren(
                createGroup(
                    for: node,
                    parentBazelPath: parentBazelPath,
                    specialRootGroupType: specialRootGroupType,
                    createGroupChild: createGroupChild
                )
            )
        }
    }
}

struct Element: Equatable {
    enum SortOrder: Comparable {
        case groupLike
        case fileLike
        case bazelExternalRepositories
        case bazelGenerated
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
