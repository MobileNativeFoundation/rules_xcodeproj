import OrderedCollections
import PBXProj

extension ElementCreator {
    struct CreateGroupChildElements {
        private let createVariantGroup: CreateVariantGroup

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createVariantGroup: CreateVariantGroup,
            callable: @escaping Callable
        ) {
            self.createVariantGroup = createVariantGroup

            self.callable = callable
        }

        /// Creates a `GroupChildElements` from an array of `GroupChild`. This
        /// function needs to exist because all of the
        /// `GroupChild.localizedRegion` for a given group need to be
        /// processed together in order to create `PBXVariantGroup` elements.
        func callAsFunction(
            parentBazelPath: BazelPath,
            groupChildren: [GroupChild],
            resolvedRepositories: [ResolvedRepository] = []
        ) -> GroupChildElements {
            return callable(
                /*parentBazelPath:*/ parentBazelPath,
                /*groupChildren:*/ groupChildren,
                /*resolvedRepositories:*/ resolvedRepositories,
                /*createVariantGroup:*/ createVariantGroup
            )
        }
    }
}

// MARK: - CreateGroupChildElements.Callable

private let localizedIBFileExtensions = [
    "storyboard",
    "xib",
    "intentdefinition",
]

extension ElementCreator.CreateGroupChildElements {
    typealias Callable = (
        _ parentBazelPath: BazelPath,
        _ groupChildren: [GroupChild],
        _ resolvedRepositories: [ResolvedRepository],
        _ createVariantGroup: ElementCreator.CreateVariantGroup
    ) -> GroupChildElements

    static func defaultCallable(
        parentBazelPath: BazelPath,
        groupChildren: [GroupChild],
        resolvedRepositories: [ResolvedRepository],
        createVariantGroup: ElementCreator.CreateVariantGroup
    ) -> GroupChildElements {
        var children: [GroupChild.ElementAndChildren] = []
        var localizedFiles: [GroupChild.LocalizedFile] = []
        for groupChild in groupChildren {
            switch groupChild {
            case .elementAndChildren(let child):
                children.append(child)

            case .localizedRegion(let files):
                localizedFiles.append(contentsOf: files)
            }
        }

        func sortLocalizedFilesByNameAndRegion(
            lhs: GroupChild.LocalizedFile,
            rhs: GroupChild.LocalizedFile
        ) -> Bool {
            let l = "\(lhs.name)\t\(lhs.region)"
            let r = "\(rhs.name)\t\(rhs.region)"
            return l.localizedCompare(r) == .orderedAscending
        }

        // We sort for 2 reasons:
        //   1. To ensure that `groupings` logic below correctly attaches
        //      `.strings` files to the right IB based file.
        //   2. To have the files inside of the variant group sorted
        //      alphabetically.
        localizedFiles.sort(by: { lhs, rhs in
            switch (lhs.ext, rhs.ext) {
            case let (lhsExt, rhsExt) where lhsExt == rhsExt:
                return sortLocalizedFilesByNameAndRegion(lhs: lhs, rhs: rhs)
            case ("intentdefinition", _): return true
            case (_, "intentdefinition"): return false
            case ("storyboard", _): return true
            case (_, "storyboard"): return false
            case ("xib", _): return true
            case (_, "xib"): return false
            case ("strings", _): return true
            case (_, "strings"): return false
            default:
                return sortLocalizedFilesByNameAndRegion(lhs: lhs, rhs: rhs)
            }
        })

        // We use an `OrderedDictionary` to keep the ordering established
        // above
        var groupings: OrderedDictionary<String, [GroupChild.LocalizedFile]> =
            [:]
        outer: for localizedFile in localizedFiles {
            if localizedFile.ext == "strings" {
                // Attempt to add the ".strings" file to an IB file of the
                // same name. Since we sorted `localizedFiles`, the "parent"
                // group will already be in `groupings`.
                let keys = groupings.keys

                for ext in localizedIBFileExtensions {
                    let key = "\(localizedFile.basenameWithoutExt).\(ext)"
                    if keys.contains(key) {
                        groupings[key]!.append(localizedFile)
                        continue outer
                    }
                }

                // Didn't find a parent, fall through to non-IB handling
            }

            groupings[localizedFile.name, default: []].append(localizedFile)
        }

        for (name, localizedFiles) in groupings {
            children.append(
                createVariantGroup(
                    name: name,
                    parentBazelPath: parentBazelPath,
                    localizedFiles: localizedFiles
                )
            )
        }

        return GroupChildElements(
            children: children,
            resolvedRepositories: resolvedRepositories
        )
    }
}

struct GroupChildElements {
    let elements: [Element]
    let transitiveObjects: [Object]
    let bazelPathAndIdentifiers: [(BazelPath, String)]
    let knownRegions: Set<String>
    let resolvedRepositories: [ResolvedRepository]
}

extension GroupChildElements {
    fileprivate init(
        children: [GroupChild.ElementAndChildren],
        resolvedRepositories: [ResolvedRepository]
    ) {
        var elements: [Element] = []
        var bazelPathAndIdentifiers: [(BazelPath, String)] = []
        var knownRegions: Set<String> = []
        var resolvedRepositories = resolvedRepositories
        var transitiveObjects: [Object] = []
        for child in children {
            elements.append(child.element)
            bazelPathAndIdentifiers
                .append(contentsOf: child.bazelPathAndIdentifiers)
            knownRegions.formUnion(child.knownRegions)
            resolvedRepositories.append(contentsOf: child.resolvedRepositories)
            transitiveObjects.append(contentsOf: child.transitiveObjects)
        }

        elements.sort()

        self.init(
            elements: elements,
            transitiveObjects: transitiveObjects,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }
}

extension GroupChildElements: Equatable {
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
            lhs.elements,
            lhs.transitiveObjects,
            lhs.knownRegions,
            lhs.resolvedRepositories
        ) == (
            rhs.elements,
            rhs.transitiveObjects,
            rhs.knownRegions,
            rhs.resolvedRepositories
        )
    }
}

extension Element: Comparable {
    static func < (lhs: Element, rhs: Element) -> Bool {
        guard lhs.sortOrder == rhs.sortOrder else {
            return lhs.sortOrder < rhs.sortOrder
        }

        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
