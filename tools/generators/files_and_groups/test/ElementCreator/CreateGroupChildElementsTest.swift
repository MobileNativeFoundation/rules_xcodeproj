import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateGroupChildElementsTest: XCTestCase {
    func test() {
        // Arrange

        let base_Main_xib = GroupChild.LocalizedFile(
            element: .init(
                name: "Main.xib",
                identifier: "Base.lproj/Main.xib id",
                content: "Base.lproj/Main.xib content",
                sortOrder: .fileLike
            ),
            region: "Base",
            name: "Main.xib",
            basenameWithoutExt: "Main",
            ext: "xib",
            bazelPaths: ["parent/Base.lproj/Main.xib"]
        )
        let base_Main_storyboard = GroupChild.LocalizedFile(
            element: .init(
                name: "Main.storyboard",
                identifier: "Base.lproj/Main.storyboard id",
                content: "Base.lproj/Main.storyboard content",
                sortOrder: .fileLike
            ),
            region: "Base",
            name: "Main.storyboard",
            basenameWithoutExt: "Main",
            ext: "storyboard",
            bazelPaths: ["parent/Base.lproj/Main.storyboard"]
        )

        let frCA_localized_strings = GroupChild.LocalizedFile(
            element: .init(
                name: "localized.strings",
                identifier: "frCA.lproj/localized.strings id",
                content: "frCA.lproj/localized.strings content",
                sortOrder: .fileLike
            ),
            region: "frCA",
            name: "localized.strings",
            basenameWithoutExt: "localized",
            ext: "strings",
            bazelPaths: ["parent/frCA.lproj/localized.strings"]
        )
        let frCA_Main_strings = GroupChild.LocalizedFile(
            element: .init(
                name: "Main.strings",
                identifier: "frCA.lproj/Main.strings id",
                content: "frCA.lproj/Main.strings content",
                sortOrder: .fileLike
            ),
            region: "frCA",
            name: "Main.strings",
            basenameWithoutExt: "Main",
            ext: "strings",
            bazelPaths: ["parent/frCA.lproj/Main.strings"]
        )

        let enGB_localized_strings = GroupChild.LocalizedFile(
            element: .init(
                name: "localized.strings",
                identifier: "enGB.lproj/localized.strings id",
                content: "enGB.lproj/localized.strings content",
                sortOrder: .fileLike
            ),
            region: "enGB",
            name: "localized.strings",
            basenameWithoutExt: "localized",
            ext: "strings",
            bazelPaths: ["parent/enGB.lproj/localized.strings"]
        )

        let parentBazelPath: BazelPath = "parent"
        let groupChildren: [GroupChild] = [
            .elementAndChildren(.init(
                element: .init(
                    name: "z",
                    identifier: "z id",
                    content: "z content",
                    sortOrder: .fileLike
                ),
                transitiveElements: [
                    .init(
                        name: "z",
                        identifier: "z id",
                        content: "z content",
                        sortOrder: .fileLike
                    ),
                ],
                bazelPathAndIdentifiers: [("parent/z", "z id")],
                knownRegions: ["z"],
                resolvedRepositories: [.init(sourcePath: "z", mappedPath: "9")]
            )),
            .elementAndChildren(.init(
                element: .init(
                    name: "localized.strings",
                    identifier: "localized.strings folder id",
                    content: "localized.strings folder content",
                    sortOrder: .groupLike
                ),
                transitiveElements: [
                    .init(
                        name: "inner",
                        identifier: "inner id",
                        content: "inner content",
                        sortOrder: .fileLike
                    ),
                    .init(
                        name: "localized.strings",
                        identifier: "localized.strings folder id",
                        content: "localized.strings folder content",
                        sortOrder: .groupLike
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("parent/a", "a id"),
                    ("parent/localized.strings/inner", "inner id"),
                    ("parent/localized.strings", "localized.strings id"),
                ],
                knownRegions: ["a"],
                resolvedRepositories: [.init(sourcePath: "a", mappedPath: "1")]
            )),
            .elementAndChildren(.init(
                element: .init(
                    name: "bazel-out",
                    identifier: "bazel-out id",
                    content: "bazel-out content",
                    sortOrder: .bazelGenerated
                ),
                transitiveElements: [
                    .init(
                        name: "bazel-out",
                        identifier: "bazel-out id",
                        content: "bazel-out content",
                        sortOrder: .bazelGenerated
                    ),
                ],
                bazelPathAndIdentifiers: [("parent/bazel-out", "bazel-out id")],
                knownRegions: ["b"],
                resolvedRepositories: [.init(sourcePath: "b", mappedPath: "3")]
            )),

            .localizedRegion([
                base_Main_xib,
                base_Main_storyboard,
            ]),

            .localizedRegion([
                frCA_localized_strings,
                frCA_Main_strings,
            ]),

            .elementAndChildren(.init(
                element: .init(
                    name: "external",
                    identifier: "external id",
                    content: "external content",
                    sortOrder: .bazelExternalRepositories
                ),
                transitiveElements: [
                    .init(
                        name: "external",
                        identifier: "external id",
                        content: "external content",
                        sortOrder: .bazelExternalRepositories
                    ),
                ],
                bazelPathAndIdentifiers: [("parent/external", "external id")],
                knownRegions: ["e"],
                resolvedRepositories: [.init(sourcePath: "e", mappedPath: "2")]
            )),

            .localizedRegion([
                enGB_localized_strings,
            ]),
        ]
        let resolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: "srcroot", mappedPath: "!"),
            .init(sourcePath: "root", mappedPath: "sudo"),
        ]

        let expectedCreateVariantGroupCalled: [
            ElementCreator.CreateVariantGroup.MockTracker.Called
        ] = [
            .init(
                name: "Main.storyboard",
                parentBazelPath: parentBazelPath,
                localizedFiles: [
                    base_Main_storyboard,
                    frCA_Main_strings,
                ]
            ),
            .init(
                name: "Main.xib",
                parentBazelPath: parentBazelPath,
                localizedFiles: [
                    base_Main_xib,
                ]
            ),
            .init(
                name: "localized.strings",
                parentBazelPath: parentBazelPath,
                localizedFiles: [
                    enGB_localized_strings,
                    frCA_localized_strings,
                ]
            ),
        ]
        let stubbedVariantGroupChildElements: [GroupChild.ElementAndChildren] = [
            .init(
                element: .init(
                    name: "Main.storyboard",
                    identifier: "Main.storyboard id",
                    content: "Main.storyboard content",
                    sortOrder: .fileLike
                ),
                transitiveElements: [
                    .init(
                        name: "Main.storyboard",
                        identifier: "Main.storyboard id",
                        content: "Main.storyboard content",
                        sortOrder: .fileLike
                    )
                ],
                bazelPathAndIdentifiers: [
                    ("parent/Base.lproj/Main.storyboard", "Main.storyboard id"),
                    ("parent/frCA.lproj/Main.strings", "Main.storyboard id"),
                ],
                knownRegions: ["Base", "frCA"],
                resolvedRepositories: []
            ),
            .init(
                element: .init(
                    name: "Main.xib",
                    identifier: "Main.xib id",
                    content: "Main.xib content",
                    sortOrder: .fileLike
                ),
                transitiveElements: [
                    .init(
                        name: "Main.xib",
                        identifier: "Main.xib id",
                        content: "Main.xib content",
                        sortOrder: .fileLike
                    )
                ],
                bazelPathAndIdentifiers: [
                    ("parent/Base.lproj/Main.xib", "Main.xib id"),
                ],
                knownRegions: ["Base"],
                resolvedRepositories: []
            ),
            .init(
                element: .init(
                    name: "localized.strings",
                    identifier: "localized.strings id",
                    content: "localized.strings content",
                    sortOrder: .fileLike
                ),
                transitiveElements: [
                    .init(
                        name: "localized.strings",
                        identifier: "localized.strings id",
                        content: "localized.strings content",
                        sortOrder: .fileLike
                    )
                ],
                bazelPathAndIdentifiers: [
                    ("parent/enGB.lproj/localized.strings", "localized.strings id"),
                    ("parent/frCA.lproj/localized.strings", "localized.strings id"),
                ],
                knownRegions: ["enGB", "frCA"],
                resolvedRepositories: []
            ),
        ]
        let createVariantGroup = ElementCreator.CreateVariantGroup
            .mock(groupChildElements: stubbedVariantGroupChildElements)

        let expectedGroupChildElements = GroupChildElements(
            elements: [
                .init(
                    name: "localized.strings",
                    identifier: "localized.strings folder id",
                    content: "localized.strings folder content",
                    sortOrder: .groupLike
                ),
                .init(
                    name: "localized.strings",
                    identifier: "localized.strings id",
                    content: "localized.strings content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "Main.storyboard",
                    identifier: "Main.storyboard id",
                    content: "Main.storyboard content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "Main.xib",
                    identifier: "Main.xib id",
                    content: "Main.xib content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "z",
                    identifier: "z id",
                    content: "z content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "external",
                    identifier: "external id",
                    content: "external content",
                    sortOrder: .bazelExternalRepositories
                ),
                .init(
                    name: "bazel-out",
                    identifier: "bazel-out id",
                    content: "bazel-out content",
                    sortOrder: .bazelGenerated
                ),
            ],
            transitiveElements: [
                .init(
                    name: "z",
                    identifier: "z id",
                    content: "z content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "inner",
                    identifier: "inner id",
                    content: "inner content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "localized.strings",
                    identifier: "localized.strings folder id",
                    content: "localized.strings folder content",
                    sortOrder: .groupLike
                ),
                .init(
                    name: "bazel-out",
                    identifier: "bazel-out id",
                    content: "bazel-out content",
                    sortOrder: .bazelGenerated
                ),
                .init(
                    name: "external",
                    identifier: "external id",
                    content: "external content",
                    sortOrder: .bazelExternalRepositories
                ),
                .init(
                    name: "Main.storyboard",
                    identifier: "Main.storyboard id",
                    content: "Main.storyboard content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "Main.xib",
                    identifier: "Main.xib id",
                    content: "Main.xib content",
                    sortOrder: .fileLike
                ),
                .init(
                    name: "localized.strings",
                    identifier: "localized.strings id",
                    content: "localized.strings content",
                    sortOrder: .fileLike
                ),
            ],
            bazelPathAndIdentifiers: [
                ("parent/z", "z id"),
                ("parent/a", "a id"),
                ("parent/localized.strings/inner", "inner id"),
                ("parent/localized.strings", "localized.strings id"),
                ("parent/bazel-out", "bazel-out id"),
                ("parent/external", "external id"),
                ("parent/Base.lproj/Main.storyboard", "Main.storyboard id"),
                ("parent/frCA.lproj/Main.strings", "Main.storyboard id"),
                ("parent/Base.lproj/Main.xib", "Main.xib id"),
                ("parent/enGB.lproj/localized.strings", "localized.strings id"),
                ("parent/frCA.lproj/localized.strings", "localized.strings id"),
            ],
            knownRegions: [
                "a",
                "b",
                "e",
                "z",
                "Base",
                "enGB",
                "frCA",
            ],
            resolvedRepositories: resolvedRepositories + [
                .init(sourcePath: "z", mappedPath: "9"),
                .init(sourcePath: "a", mappedPath: "1"),
                .init(sourcePath: "b", mappedPath: "3"),
                .init(sourcePath: "e", mappedPath: "2"),
            ]
        )

        // Act

        let groupChildElements = ElementCreator.CreateGroupChildElements
            .defaultCallable(
                parentBazelPath: parentBazelPath,
                groupChildren: groupChildren,
                resolvedRepositories: resolvedRepositories,
                createVariantGroup: createVariantGroup.mock
            )

        // Assert

        XCTAssertNoDifference(
            createVariantGroup.tracker.called,
            expectedCreateVariantGroupCalled
        )
        XCTAssertNoDifference(groupChildElements, expectedGroupChildElements)
    }
}
