import PBXProj

extension ElementCreator {
    static func element(
        node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createFile: Environment.CreateFile,
        createGroup: Environment.CreateGroup,
        createVariantGroup: Environment.CreateVariantGroup,
        createVersionGroup: Environment.CreateVersionGroup,
        collectBazelPaths: Environment.CollectBazelPaths
    ) -> (
        element: Element,
        transitiveElements: [Element],
        bazelPathAndIdentifiers: [(BazelPath, String)],
        knownRegions: Set<String>,
        resolvedRepositories: [ResolvedRepository]
    ) {
        let element: Element
        let transitiveElements: [Element]
        let bazelPathAndIdentifiers: [(BazelPath, String)]
        let knownRegions: Set<String> = []
        let resolvedRepositories: [ResolvedRepository]

        if node.children.isEmpty {
            // File
            let result = createFile(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType
            )
            element = result.element
            transitiveElements = [element]
            resolvedRepositories = result.resolvedRepository.map { [$0] } ?? []

            let bazelPaths = collectBazelPaths(
                /*node:*/ node,
                /*bazelPath:*/ result.bazelPath
            )
            bazelPathAndIdentifiers = bazelPaths
                .map { ($0, element.identifier) }
        } else {
            fatalError()
            // Group
            let (basenameWithoutExt, ext) = node.splitExtension()
            switch ext {
            case "lproj":
                fatalError("TODO")
//                let a = createVariantGroup(<#T##String#>, <#T##String#>, <#T##SourceTree#>, <#T##[String]#>, <#T##(String, Identifiers.FilesAndGroups.ElementType, inout Set<String>) -> String##(String, Identifiers.FilesAndGroups.ElementType, inout Set<String>) -> String##(_ path: String, _ type: Identifiers.FilesAndGroups.ElementType, _ hashCache: inout Set<String>) -> String#>)

            case "xcdatamodeld":
                let childIdentifiers: [String] = []
                let selectedChildIdentifier = ""

                let b = createVersionGroup(
                    /*node:*/ node,
                    /*parentBazelPath:*/ parentBazelPath,
                    /*specialRootGroupType:*/ specialRootGroupType,
                    /*childIdentifiers:*/ childIdentifiers,
                    /*selectedChildIdentifier:*/ selectedChildIdentifier
               )

            default:
                let childIdentifiers: [String] = []

                let c = createGroup(
                    /*node:*/ node,
                    /*parentBazelPath:*/ parentBazelPath,
                    /*specialRootGroupType:*/ specialRootGroupType,
                    /*childIdentifiers:*/ childIdentifiers
                )
            }
        }

        return (
            element: element,
            transitiveElements: transitiveElements,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: knownRegions,
            resolvedRepositories: resolvedRepositories
        )
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

    let identifier: String
    let content: String
    let sortOrder: SortOrder
}


private extension PathTreeNode {
    func splitExtension() -> (base: String, ext: String?) {
        guard let extIndex = name.lastIndex(of: ".") else {
            return (name, nil)
        }
        return (
            String(name[name.startIndex..<extIndex]),
            String(name[name.index(after: extIndex)..<name.endIndex])
        )
    }
}
