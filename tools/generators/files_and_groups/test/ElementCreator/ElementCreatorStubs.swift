import PBXProj

@testable import files_and_groups

extension ElementCreator {
    enum Stubs {
        static let collectBazelPaths = CollectBazelPaths.stub(bazelPaths: [])

        static let createAttributes = CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group,
                name: nil,
                path: "a/path"
            ),
            resolvedRepository: nil
        )

        static let createFile = CreateFile.stub(
            groupChildElement: [
                GroupChild.ElementAndChildren(
                    element: Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .fileLike
                    ),
                    transitiveObjects: [],
                    bazelPathAndIdentifiers: [],
                    knownRegions: [],
                    resolvedRepositories: []
                ),
            ]
        )

        static let createFileElement = CreateFileElement.stub(
            results: [
                (
                    element: Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .fileLike
                    ),
                    resolvedRepository: nil
                ),
            ]
        )

        static let createGroup = CreateGroup.stub(
            groupChildElement: GroupChild.ElementAndChildren(
                element: Element(
                    name: "Name",
                    object: .init(
                        identifier: "Identifier",
                        content: "Content"
                    ),
                    sortOrder: .groupLike
                ),
                transitiveObjects: [],
                bazelPathAndIdentifiers: [],
                knownRegions: [],
                resolvedRepositories: []
            )
        )

        static let createGroupChild = CreateGroupChild.stub(
            children: [
                .elementAndChildren(.init(
                    element: Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .fileLike
                    ),
                    transitiveObjects: [],
                    bazelPathAndIdentifiers: [],
                    knownRegions: [],
                    resolvedRepositories: []
                )),
            ]
        )

        static let createGroupChildElements = CreateGroupChildElements.stub(
            groupChildElements: GroupChildElements(
                elements: [
                    Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .fileLike
                    ),
                ],
                transitiveObjects: [],
                bazelPathAndIdentifiers: [],
                knownRegions: [],
                resolvedRepositories: []
            )
        )

        static let createGroupElement = CreateGroupElement.stub(
            element: Element(
                name: "Name",
                object: .init(
                    identifier: "Identifier",
                    content: "Content"
                ),
                sortOrder: .groupLike
            ),
            resolvedRepository: nil
        )
        
        static let createIdentifier = CreateIdentifier.stub(
            identifier: "Identifier"
        )

        static let createLocalizedFiles = CreateLocalizedFiles.stub(
            localizedFiles: [
                GroupChild.LocalizedFile(
                    element: Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .fileLike
                    ),
                    region: "region",
                    name: "basename.ext",
                    basenameWithoutExt: "basename",
                    ext: "ext",
                    bazelPaths: []
                )
            ]
        )

        static let createSpecialRootGroup = CreateSpecialRootGroup.stub(
            groupChildElements: [
                GroupChild.ElementAndChildren(
                    element: Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .groupLike
                    ),
                    transitiveObjects: [],
                    bazelPathAndIdentifiers: [],
                    knownRegions: [],
                    resolvedRepositories: []
                ),
            ]
        )

        static let createSpecialRootGroupElement = CreateSpecialRootGroupElement
            .stub(
                element: Element(
                    name: "Name",
                    object: .init(
                        identifier: "Identifier",
                        content: "Content"
                    ),
                    sortOrder: .fileLike
                )
            )

        static let createVariantGroup = CreateVariantGroup.stub(
            groupChildElements: [
                GroupChild.ElementAndChildren(
                    element: Element(
                        name: "Name",
                        object: .init(
                            identifier: "Identifier",
                            content: "Content"
                        ),
                        sortOrder: .fileLike
                    ),
                    transitiveObjects: [],
                    bazelPathAndIdentifiers: [],
                    knownRegions: [],
                    resolvedRepositories: []
                ),
            ]
        )

        static let createVariantGroupElement = CreateVariantGroupElement.stub(
            element: Element(
                name: "Name",
                object: .init(
                    identifier: "Identifier",
                    content: "Content"
                ),
                sortOrder: .fileLike
            )
        )

        static let createVersionGroup = CreateVersionGroup.stub(
            groupChildElement: GroupChild.ElementAndChildren(
                element: Element(
                    name: "Name",
                    object: .init(
                        identifier: "Identifier",
                        content: "Content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [],
                bazelPathAndIdentifiers: [],
                knownRegions: [],
                resolvedRepositories: []
            )
        )

        static let createVersionGroupElement = CreateVersionGroupElement.stub(
            element: Element(
                name: "Name",
                    object: .init(
                    identifier: "Identifier",
                    content: "Content"
                ),
                sortOrder: .fileLike
            ),
            resolvedRepository: nil
        )
    }
}
