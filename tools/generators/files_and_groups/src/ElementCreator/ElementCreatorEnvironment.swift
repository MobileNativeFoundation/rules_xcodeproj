import Foundation
import PBXProj

extension ElementCreator {
    /// Provides the callable dependencies for `ElementCreator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        /// Passed to the `callable` parameter of `CreateAttributes.init()`.
        let createAttributesCallable: CreateAttributes.Callable

        /// Passed to the `callable` parameter of `CreateFile.init()`.
        let createFileCallable: CreateFile.Callable

        /// Passed to the `callable` parameter of `CreateGroup.init()`.
        let createGroupCallable: CreateGroup.Callable

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

        let externalDir: CalculateExternalDir

        typealias MainCreateGroup = (
            _ rootElements: [Element],
            _ workspace: String
        ) -> String
        let mainGroup: MainCreateGroup

        let partial: CalculatePartial

        let readExecutionRootFile: (_ url: URL) throws -> String

        let resolveSymlink: ResolveSymlink

        let rootElements: (
            _ pathTree: PathTreeNode,
            _ workspace: String,
            _ createElementAttributes: CreateAttributes,
            _ createSpecialRootGroup: CreateSpecialRootGroup
        ) -> (
            rootElements: [Element],
            allElements: [Element],
            pathsToIdentifiers: [BazelPath: String],
            knownRegions: Set<String>,
            resolvedRepositories: [ResolvedRepository]
        )

        typealias CreateSpecialRootGroup = (
            _ specialRootGroupType: SpecialRootGroupType,
            _ childIdentifiers: [String]
        ) -> Element
        let specialRootGroup: CreateSpecialRootGroup

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
        createAttributesCallable:
            ElementCreator.CreateAttributes.defaultCallable,
        createFileCallable: ElementCreator.CreateFile.defaultCallable,
        createGroupCallable: ElementCreator.CreateGroup.defaultCallable,
        collectBazelPaths: ElementCreator.CollectBazelPaths(),
        element: ElementCreator.element,
        externalDir: ElementCreator.CalculateExternalDir(),
        mainGroup: ElementCreator.mainGroup,
        partial: ElementCreator.CalculatePartial(),
        readExecutionRootFile: ElementCreator.readExecutionRootFile,
        resolveSymlink: ElementCreator.ResolveSymlink(),
        rootElements: ElementCreator.rootElements,
        specialRootGroup: ElementCreator.specialRootGroup,
        variantGroup: ElementCreator.variantGroup,
        versionGroup: ElementCreator.versionGroup
    )
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
        _ createIdentifier: ElementCreator.CreateIdentifier
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
        _ createAttributes: ElementCreator.CreateAttributes,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> CreateVersionGroup {
        return { node, parentBazelPath, specialRootGroupType, childIdentifiers, selectedChildIdentifier in
            return versionGroup(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*childIdentifiers:*/ childIdentifiers,
                /*selectedChildIdentifier:*/ selectedChildIdentifier,
                /*createAttributes:*/ createAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}
