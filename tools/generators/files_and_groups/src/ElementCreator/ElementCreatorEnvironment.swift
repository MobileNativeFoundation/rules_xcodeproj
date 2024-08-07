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

        /// Passed to the `callable` parameter of
        /// `CreateExternalRepositoriesGroup.init()`.
        let createExternalRepositoriesGroupCallable:
            CreateExternalRepositoriesGroup.Callable

        let createExternalRepositoriesGroupElement:
            CreateExternalRepositoriesGroupElement

        /// Passed to the `callable` parameter of `CreateFile.init()`.
        let createFileCallable: CreateFile.Callable

        /// Passed to the `callable` parameter of `CreateFileElement.init()`.
        let createFileElementCallable: CreateFileElement.Callable

        /// Passed to the `callable` parameter of `CreateGroup.init()`.
        let createGroupCallable: CreateGroup.Callable

        /// Passed to the `callable` parameter of `CreateGroupChild.init()`.
        let createGroupChildCallable: CreateGroupChild.Callable

        /// Passed to the `callable` parameter of `CreateGroup.init()`.
        let createGroupElementCallable: CreateGroupElement.Callable

        /// Passed to the `callable` parameter of
        /// `CreateGroupChildElements.init()`.
        let createGroupChildElementsCallable: CreateGroupChildElements.Callable

        let createIdentifier: CreateIdentifier

        let createInlineBazelGeneratedConfigGroupCallable:
            CreateInlineBazelGeneratedConfigGroup.Callable

        let createInlineBazelGeneratedConfigGroupElementCallable:
            CreateInlineBazelGeneratedConfigGroupElement.Callable

        let createInlineBazelGeneratedFilesCallable:
            CreateInlineBazelGeneratedFiles.Callable

        let createInternalGroupCallable: CreateInternalGroup.Callable

        /// Passed to the `callable` parameter of
        /// `CreateLocalizedFileElement.init()`.
        let createLocalizedFileElementCallable:
            CreateLocalizedFileElement.Callable

        /// Passed to the `callable` parameter of `CreateLocalizedFiles.init()`.
        let createLocalizedFilesCallable: CreateLocalizedFiles.Callable

        let createMainGroupContent: CreateMainGroupContent

        /// Passed to the `callable` parameter of `CreateRootElements.init()`.
        let createRootElementsCallable: CreateRootElements.Callable

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

        let createLocalizedFileElement =
            ElementCreator.CreateLocalizedFileElement(
                createIdentifier: createIdentifier,
                callable: createLocalizedFileElementCallable
            )

        let createLocalizedFiles = ElementCreator.CreateLocalizedFiles(
            collectBazelPaths: collectBazelPaths,
            createLocalizedFileElement: createLocalizedFileElement,
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
            collectBazelPaths: collectBazelPaths,
            selectedModelVersions: selectedModelVersions,
            callable: createVersionGroupCallable
        )

        let createInlineBazelGeneratedConfigGroupElement =
        ElementCreator.CreateInlineBazelGeneratedConfigGroupElement(
            createIdentifier: createIdentifier,
            callable: createInlineBazelGeneratedConfigGroupElementCallable
        )
        let createInlineBazelGeneratedConfigGroup =
        ElementCreator.CreateInlineBazelGeneratedConfigGroup(
            createGroupChildElements: createGroupChildElements,
            createInlineBazelGeneratedConfigGroupElement:
                createInlineBazelGeneratedConfigGroupElement,
            callable: createInlineBazelGeneratedConfigGroupCallable
        )
        let createInlineBazelGeneratedFilesElement =
        ElementCreator.CreateInlineBazelGeneratedFilesElement(
            createIdentifier: createIdentifier
        )
        let createInlineBazelGeneratedFiles =
        ElementCreator.CreateInlineBazelGeneratedFiles(
            createGroupChildElements: createGroupChildElements,
            createInlineBazelGeneratedConfigGroup:
                createInlineBazelGeneratedConfigGroup,
            createInlineBazelGeneratedFilesElement:
                createInlineBazelGeneratedFilesElement,
            callable: createInlineBazelGeneratedFilesCallable
        )

        let createGroupChild = ElementCreator.CreateGroupChild(
            createFile: createFile,
            createGroup: createGroup,
            createInlineBazelGeneratedFiles: createInlineBazelGeneratedFiles,
            createLocalizedFiles: createLocalizedFiles,
            createVersionGroup: createVersionGroup,
            callable: createGroupChildCallable
        )

        let createInternalGroup = ElementCreator.CreateInternalGroup(
            callable: createInternalGroupCallable
        )

        let createExternalRepositoriesGroup =
            ElementCreator.CreateExternalRepositoriesGroup(
                createExternalRepositoriesGroupElement:
                    createExternalRepositoriesGroupElement,
                createGroupChild: createGroupChild,
                createGroupChildElements: createGroupChildElements,
                callable: createExternalRepositoriesGroupCallable
            )

        return ElementCreator.CreateRootElements(
            includeCompileStub: includeCompileStub,
            installPath: installPath,
            workspace: workspace,
            createExternalRepositoriesGroup: createExternalRepositoriesGroup,
            createGroupChild: createGroupChild,
            createGroupChildElements: createGroupChildElements,
            createInternalGroup: createInternalGroup,
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
        createExternalRepositoriesGroupCallable:
            ElementCreator.CreateExternalRepositoriesGroup.defaultCallable,
        createExternalRepositoriesGroupElement:
            ElementCreator.CreateExternalRepositoriesGroupElement(),
        createFileCallable: ElementCreator.CreateFile.defaultCallable,
        createFileElementCallable:
            ElementCreator.CreateFileElement.defaultCallable,
        createGroupCallable: ElementCreator.CreateGroup.defaultCallable,
        createGroupChildCallable:
            ElementCreator.CreateGroupChild.defaultCallable,
        createGroupElementCallable:
            ElementCreator.CreateGroupElement.defaultCallable,
        createGroupChildElementsCallable:
            ElementCreator.CreateGroupChildElements.defaultCallable,
        createIdentifier: ElementCreator.CreateIdentifier(),
        createInlineBazelGeneratedConfigGroupCallable:
            ElementCreator.CreateInlineBazelGeneratedConfigGroup
                .defaultCallable,
        createInlineBazelGeneratedConfigGroupElementCallable:
            ElementCreator.CreateInlineBazelGeneratedConfigGroupElement
                .defaultCallable,
        createInlineBazelGeneratedFilesCallable:
            ElementCreator.CreateInlineBazelGeneratedFiles.defaultCallable,
        createInternalGroupCallable:
            ElementCreator.CreateInternalGroup.defaultCallable,
        createLocalizedFileElementCallable:
            ElementCreator.CreateLocalizedFileElement.defaultCallable,
        createLocalizedFilesCallable:
            ElementCreator.CreateLocalizedFiles.defaultCallable,
        createMainGroupContent: ElementCreator.CreateMainGroupContent(),
        createRootElementsCallable:
            ElementCreator.CreateRootElements.defaultCallable,
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
