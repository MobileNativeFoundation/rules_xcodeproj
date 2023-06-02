import PBXProj

@testable import files_and_groups

extension ElementCreator {
    enum Stubs {
        static let createAttributes = CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group,
                name: nil,
                path: "a/path"
            ),
            resolvedRepository: nil
        )

        static let createIdentifier = CreateIdentifier.stub(
            identifier: "Identifier"
        )

        static func specialRootGroup(
            specialRootGroupType: SpecialRootGroupType,
            childIdentifiers: [String]
        ) -> Element {
            return Element(
                identifier: "\(specialRootGroupType) Identifier",
                content: "\(specialRootGroupType) Content",
                sortOrder: .groupLike
            )
        }
    }
}
