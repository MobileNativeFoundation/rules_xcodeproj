import PBXProj

@testable import files_and_groups

extension ElementCreator {
    enum Stubs {
        static func attributes(
            name: String,
            bazelPath: BazelPath,
            isGroup: Bool,
            specialRootGroupType: SpecialRootGroupType?
        ) -> (
            elementAttributes: ElementAttributes,
            resolvedRepository: ResolvedRepository?
        ) {
            return (
                elementAttributes: ElementAttributes(
                    sourceTree: .group,
                    name: nil,
                    path: name
                ),
                resolvedRepository: nil
            )
        }

        static func identifier(
            path: String,
            type: Identifiers.FilesAndGroups.ElementType
        ) -> String {
            return "\(path) \(type)"
        }
    }
}
