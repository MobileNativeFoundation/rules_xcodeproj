import Foundation
import PBXProj

extension ElementCreator {
    /// Provides the callable dependencies for `ElementCreator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let attributes: (
            _ name: String,
            _ bazelPath: BazelPath,
            _ isGroup: Bool,
            _ specialRootGroupType: SpecialRootGroupType?,
            _ executionRoot: String,
            _ externalDir: String,
            _ workspace: String,
            _ resolveSymlink: (_ path: String) -> String?
        ) -> (
            elementAttributes: ElementAttributes,
            resolvedRepository: ResolvedRepository?
        )

        typealias CollectBazelPaths = (
            _ node: PathTreeNode,
            _ bazelPath: BazelPath
        ) -> [BazelPath]
        let collectBazelPaths: CollectBazelPaths

        let element: (
            _ node: PathTreeNode,
            _ parentBazelPath: BazelPath,
            _ specialRootGroupType: SpecialRootGroupType?,
            _ createFile: CreateFile,
            _ createGroup: CreateGroup,
            _ createVariantGroup: CreateVariantGroup,
            _ createVersionGroup: CreateVersionGroup,
            _ collectBazelPaths: CollectBazelPaths
        ) -> (
            element: Element,
            transitiveElements: [Element],
            bazelPathAndIdentifiers: [(BazelPath, String)],
            knownRegions: Set<String>,
            resolvedRepositories: [ResolvedRepository]
        )

        let externalDir: (_ executionRoot: String) throws -> String

        let file: (
            _ node: PathTreeNode,
            _ parentBazelPath: BazelPath,
            _ specialRootGroupType: SpecialRootGroupType?,
            _ elementAttributes: CreateAttributes,
            _ createIdentifier: CreateIdentifier
        ) -> (
            element: Element,
            bazelPath: BazelPath,
            resolvedRepository: ResolvedRepository?
        )

        let group: (
            _ node: PathTreeNode,
            _ parentBazelPath: BazelPath,
            _ specialRootGroupType: SpecialRootGroupType?,
            _ childIdentifiers: [String],
            _ elementAttributes: CreateAttributes,
            _ createIdentifier: CreateIdentifier
        ) -> (
            element: Element,
            resolvedRepository: ResolvedRepository?
        )

        typealias MainCreateGroup = (
            _ rootElements: [Element],
            _ workspace: String
        ) -> String
        let mainGroup: MainCreateGroup

        let partial: (
            _ elements: [Element],
            _ mainGroup: String,
            _ workspace: String
        ) -> String

        let readExecutionRootFile: (_ url: URL) throws -> String

        let resolveSymlink: (_ path: String) -> String?

        let rootElements: (
            _ pathTree: PathTreeNode,
            _ workspace: String,
            _ elementAttributes: CreateAttributes
        ) -> (
            rootElements: [Element],
            allElements: [Element],
            pathsToIdentifiers: [BazelPath: String],
            knownRegions: Set<String>,
            resolvedRepositories: [ResolvedRepository]
        )

        typealias SpecialRootCreateGroup = (
            _ specialRootGroupType: SpecialRootGroupType,
            _ childIdentifiers: [String]
        ) -> Element
        let specialRootGroup: SpecialRootCreateGroup

        let variantGroup: (
            _ name: String,
            _ bazelPathStr: String,
            _ sourceTree: SourceTree,
            _ childIdentifiers: [String],
            _ createIdentifier: CreateIdentifier
        ) -> Element

        let versionGroup: (
            _ node: PathTreeNode,
            _ parentBazelPath: BazelPath,
            _ specialRootGroupType: SpecialRootGroupType?,
            _ childIdentifiers: [String],
            _ selectedChildIdentifier: String,
            _ elementAttributes: CreateAttributes,
            _ createIdentifier: CreateIdentifier
        ) -> (
            element: Element,
            resolvedRepository: ResolvedRepository?
        )
    }
}

extension ElementCreator.Environment {
    static let `default` = Self(
        attributes: ElementCreator.attributes,
        collectBazelPaths: ElementCreator.collectBazelPaths,
        element: ElementCreator.element,
        externalDir: ElementCreator.externalDir,
        file: ElementCreator.file,
        group: ElementCreator.group,
        mainGroup: ElementCreator.mainGroup,
        partial: ElementCreator.partial,
        readExecutionRootFile: ElementCreator.readExecutionRootFile,
        resolveSymlink: ElementCreator.resolveSymlink,
        rootElements: ElementCreator.rootElements,
        specialRootGroup: ElementCreator.specialRootGroup,
        variantGroup: ElementCreator.variantGroup,
        versionGroup: ElementCreator.versionGroup
    )
}

// MARK: - Environment.CreateAttributes

extension ElementCreator.Environment {
    /// A version of `attributes` that has access to its dependencies
    /// (via closure capture).
    typealias CreateAttributes = (
        _ name: String,
        _ bazelPath: BazelPath,
        _ isGroup: Bool,
        _ specialRootGroupType: SpecialRootGroupType?
    ) -> (
        elementAttributes: ElementAttributes,
        resolvedRepository: ResolvedRepository?
    )

    func attributesWithDependencies(
        executionRoot: String,
        externalDir: String,
        workspace: String,
        resolveSymlink: @escaping (_ path: String) -> String?
    ) -> CreateAttributes {
        return { name, bazelPath, isGroup, specialRootGroupType in
            return attributes(
                /*name:*/ name,
                /*bazelPath:*/ bazelPath,
                /*isGroup:*/ isGroup,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*executionRoot:*/ executionRoot,
                /*externalDir:*/ externalDir,
                /*workspace:*/ workspace,
                /*resolveSymlink:*/ resolveSymlink
            )
        }
    }
}

// MARK: - Environment.CreateFile

extension ElementCreator.Environment {
    typealias CreateFile = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?
    ) -> (
        element: Element,
        bazelPath: BazelPath,
        resolvedRepository: ResolvedRepository?
    )

    func fileWithDependencies(
        node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        elementAttributes: @escaping CreateAttributes,
        createIdentifier: @escaping CreateIdentifier
    ) -> CreateFile {
        return { node, parentBazelPath, specialRootGroupType in
            return file(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*elementAttributes:*/ elementAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - Environment.CreateGroup

extension ElementCreator.Environment {
    typealias CreateGroup = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ childIdentifiers: [String]
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    )

    func groupWithDependencies(
        elementAttributes: @escaping CreateAttributes,
        createIdentifier: @escaping CreateIdentifier
    ) -> CreateGroup {
        return { node, parentBazelPath, specialRootGroupType, childIdentifiers in
            return group(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*childIdentifiers:*/ childIdentifiers,
                /*elementAttributes:*/ elementAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - Environment.CreateIdentifier

extension ElementCreator.Environment {
    typealias CreateIdentifier = (
        _ path: String,
        _ type: Identifiers.FilesAndGroups.ElementType
    ) -> String

    func identifierWithDependencies() -> CreateIdentifier {
        return { path, type in
            var hashCache: Set<String> = []
            return Identifiers.FilesAndGroups.element(
                path,
                type: type,
                hashCache: &hashCache
            )
        }
    }
}

// MARK: - Environment.CreateVariantGroup

extension ElementCreator.Environment {
    typealias CreateVariantGroup = (
        _ name: String,
        _ bazelPathStr: String,
        _ sourceTree: SourceTree,
        _ childIdentifiers: [String]
    ) -> Element

    func variantGroupWithDependencies(
        _ createIdentifier: @escaping CreateIdentifier
    ) -> CreateVariantGroup {
        return { name, bazelPathStr, sourceTree, childIdentifiers in
            return variantGroup(
                /*name:*/ name,
                /*bazelPathStr:*/ bazelPathStr,
                /*sourceTree:*/ sourceTree,
                /*childIdentifiers:*/ childIdentifiers,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - Environment.CreateVersionGroup

extension ElementCreator.Environment {
    typealias CreateVersionGroup = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ childIdentifiers: [String],
        _ selectedChildIdentifier: String
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    )

    func versionGroupWithDependencies(
        _ elementAttributes: @escaping CreateAttributes,
        _ createIdentifier: @escaping CreateIdentifier
    ) -> CreateVersionGroup {
        return { node, parentBazelPath, specialRootGroupType, childIdentifiers, selectedChildIdentifier in
            return versionGroup(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*childIdentifiers:*/ childIdentifiers,
                /*selectedChildIdentifier:*/ selectedChildIdentifier,
                /*elementAttributes:*/ elementAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}
