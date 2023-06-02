import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateAttributes.mock

extension ElementCreator.CreateAttributes {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let bazelPath: BazelPath
            let isGroup: Bool
            let specialRootGroupType: SpecialRootGroupType?
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        elementAttributes: ElementAttributes,
        resolvedRepository: ResolvedRepository?
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            executionRoot: "",
            externalDir: "",
            workspace: "",
            resolveSymlink:
                ElementCreator.ResolveSymlink.stub(symlinkDest: nil),
            callable: {
                name,
                bazelPath,
                isGroup,
                specialRootGroupType,
                executionRoot,
                externalDir,
                workspace,
                resolveSymlink
            in
                mockTracker.called.append(.init(
                    name: name,
                    bazelPath: bazelPath,
                    isGroup: isGroup,
                    specialRootGroupType: specialRootGroupType
                ))
                return (elementAttributes, resolvedRepository)
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateAttributes.stub

extension ElementCreator.CreateAttributes {
    static func stub(
        elementAttributes: ElementAttributes,
        resolvedRepository: ResolvedRepository?
    ) -> Self {
        let (stub, _) = mock(
            elementAttributes: elementAttributes,
            resolvedRepository: resolvedRepository
        )
        return stub
    }
}
