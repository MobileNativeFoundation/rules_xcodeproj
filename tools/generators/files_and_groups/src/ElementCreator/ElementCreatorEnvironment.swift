import Foundation
import PBXProj

extension ElementCreator {
    /// Provides the callable dependencies for `ElementCreator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculatePartial: CalculatePartial

        let collectBazelPaths: CollectBazelPaths

        /// Passed to the `callable` parameter of `CreateAttributes.init()`.
        let createAttributesCallable: CreateAttributes.Callable

        /// Passed to the `callable` parameter of `CreateGroupChild.init()`.
        let createGroupChildCallable: CreateGroupChild.Callable

        /// Passed to the `callable` parameter of `CreateFile.init()`.
        let createFileCallable: CreateFile.Callable

        /// Passed to the `callable` parameter of `CreateFileElement.init()`.
        let createFileElementCallable: CreateFileElement.Callable

        /// Passed to the `callable` parameter of `CreateGroup.init()`.
        let createGroupCallable: CreateGroup.Callable

        /// Passed to the `callable` parameter of `CreateGroup.init()`.
        let createGroupElementCallable: CreateGroupElement.Callable

        /// Passed to the `callable` parameter of
        /// `CreateGroupChildElements.init()`.
        let createGroupChildElementsCallable: CreateGroupChildElements.Callable

        let createIdentifier: CreateIdentifier

        let createInternalGroupCallable: CreateInternalGroup.Callable

        /// Passed to the `callable` parameter of `CreateLocalizedFiles.init()`.
        let createLocalizedFilesCallable: CreateLocalizedFiles.Callable

        let createMainGroupContent: CreateMainGroupContent

        /// Passed to the `callable` parameter of `CreateRootElements.init()`.
        let createRootElementsCallable: CreateRootElements.Callable

        /// Passed to the `callable` parameter of
        /// `CreateSpecialRootGroup.init()`.
        let createSpecialRootGroupCallable: CreateSpecialRootGroup.Callable

        let createSpecialRootGroupElement: CreateSpecialRootGroupElement

        /// Passed to the `callable` parameter of `CreateVariantGroup.init()`.
        let createVariantGroupCallable: CreateVariantGroup.Callable

        /// Passed to the `callable` parameter of
        /// `CreateVariantElementGroup.init()`.
        let createVariantGroupElementCallable:
            CreateVariantGroupElement.Callable

        /// Passed to the `callable` parameter of `CreateVersionGroup.init()`.
        let createVersionGroupCallable: CreateVersionGroup.Callable

        /// Passed to the `callable` parameter of
        /// `CreateVersionGroupElement.init()`.
        let createVersionGroupElementCallable:
            CreateVersionGroupElement.Callable

        let externalDir: CalculateExternalDir

        let readExecutionRootFile: ReadExecutionRootFile

        let readSelectedModelVersionsFile: ReadSelectedModelVersionsFile

        let resolveSymlink: ResolveSymlink
    }
}

extension ElementCreator.Environment {
    func createCreateRootElements(
        executionRoot: String,
        externalDir: String,
        includeCompileStub: Bool,
        installPath: String,
        selectedModelVersions: [BazelPath: String],
        workspace: String
    ) -> ElementCreator.CreateRootElements {
        let createAttributes = ElementCreator.CreateAttributes(
            executionRoot: executionRoot,
            externalDir: externalDir,
            workspace: workspace,
            resolveSymlink: resolveSymlink,
            callable: createAttributesCallable
        )

        let createFileElement = ElementCreator.CreateFileElement(
            createAttributes: createAttributes,
            createIdentifier: createIdentifier,
            callable: createFileElementCallable
        )
        let createFile = ElementCreator.CreateFile(
            collectBazelPaths: collectBazelPaths,
            createFileElement: createFileElement,
            callable: createFileCallable
        )

        let createVariantGroupElement = ElementCreator
            .CreateVariantGroupElement(
                createIdentifier: createIdentifier,
                callable: createVariantGroupElementCallable
            )
        let createVariantGroup = ElementCreator.CreateVariantGroup(
            createVariantGroupElement: createVariantGroupElement,
            callable: createVariantGroupCallable
        )

        let createGroupChildElements =
            ElementCreator.CreateGroupChildElements(
                createVariantGroup: createVariantGroup,
                callable: createGroupChildElementsCallable
            )

        let createGroupElement = ElementCreator.CreateGroupElement(
            createAttributes: createAttributes,
            createIdentifier: createIdentifier,
            callable: createGroupElementCallable
        )
        let createGroup = ElementCreator.CreateGroup(
            createGroupChildElements: createGroupChildElements,
            createGroupElement: createGroupElement,
            callable: createGroupCallable
        )

        let createLocalizedFiles = ElementCreator.CreateLocalizedFiles(
            collectBazelPaths: collectBazelPaths,
            createFileElement: createFileElement,
            callable: createLocalizedFilesCallable
        )

        let createVersionGroupElement = ElementCreator
            .CreateVersionGroupElement(
                createAttributes: createAttributes,
                callable: createVersionGroupElementCallable
            )
        let createVersionGroup = ElementCreator.CreateVersionGroup(
            createFile: createFile,
            createIdentifier: createIdentifier,
            createVersionGroupElement: createVersionGroupElement,
            selectedModelVersions: selectedModelVersions,
            callable: createVersionGroupCallable
        )

        let createGroupChild = ElementCreator.CreateGroupChild(
            createFile: createFile,
            createGroup: createGroup,
            createLocalizedFiles: createLocalizedFiles,
            createVersionGroup: createVersionGroup,
            callable: createGroupChildCallable
        )

        let createInternalGroup = ElementCreator.CreateInternalGroup(
            callable: createInternalGroupCallable
        )

        let createSpecialRootGroup = ElementCreator.CreateSpecialRootGroup(
            createGroupChild: createGroupChild,
            createGroupChildElements: createGroupChildElements,
            createSpecialRootGroupElement: createSpecialRootGroupElement,
            callable: createSpecialRootGroupCallable
        )

        return ElementCreator.CreateRootElements(
            includeCompileStub: includeCompileStub,
            installPath: installPath,
            workspace: workspace,
            createGroupChild: createGroupChild,
            createGroupChildElements: createGroupChildElements,
            createInternalGroup: createInternalGroup,
            createSpecialRootGroup: createSpecialRootGroup,
            callable: createRootElementsCallable
        )
    }
}

extension ElementCreator.Environment {
    static let `default` = Self(
        calculatePartial: ElementCreator.CalculatePartial(),
        collectBazelPaths: ElementCreator.CollectBazelPaths(),
        createAttributesCallable:
            ElementCreator.CreateAttributes.defaultCallable,
        createGroupChildCallable:
            ElementCreator.CreateGroupChild.defaultCallable,
        createFileCallable: ElementCreator.CreateFile.defaultCallable,
        createFileElementCallable:
            ElementCreator.CreateFileElement.defaultCallable,
        createGroupCallable: ElementCreator.CreateGroup.defaultCallable,
        createGroupElementCallable:
            ElementCreator.CreateGroupElement.defaultCallable,
        createGroupChildElementsCallable:
            ElementCreator.CreateGroupChildElements.defaultCallable,
        createIdentifier: ElementCreator.CreateIdentifier(),
        createInternalGroupCallable:
            ElementCreator.CreateInternalGroup.defaultCallable,
        createLocalizedFilesCallable:
            ElementCreator.CreateLocalizedFiles.defaultCallable,
        createMainGroupContent: ElementCreator.CreateMainGroupContent(),
        createRootElementsCallable:
            ElementCreator.CreateRootElements.defaultCallable,
        createSpecialRootGroupCallable:
            ElementCreator.CreateSpecialRootGroup.defaultCallable,
        createSpecialRootGroupElement:
            ElementCreator.CreateSpecialRootGroupElement(),
        createVariantGroupCallable:
            ElementCreator.CreateVariantGroup.defaultCallable,
        createVariantGroupElementCallable:
            ElementCreator.CreateVariantGroupElement.defaultCallable,
        createVersionGroupCallable:
            ElementCreator.CreateVersionGroup.defaultCallable,
        createVersionGroupElementCallable:
            ElementCreator.CreateVersionGroupElement.defaultCallable,
        externalDir: ElementCreator.CalculateExternalDir(),
        readExecutionRootFile: ElementCreator.ReadExecutionRootFile(),
        readSelectedModelVersionsFile:
            ElementCreator.ReadSelectedModelVersionsFile(),
        resolveSymlink: ElementCreator.ResolveSymlink()
    )
}
