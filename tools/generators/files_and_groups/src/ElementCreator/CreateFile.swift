import PBXProj

extension ElementCreator {
    struct CreateFile {
        private let createFileElement: CreateFileElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createFileElement: CreateFileElement,
            callable: @escaping Callable
        ) {
            self.createFileElement = createFileElement

            self.callable = callable
        }

        func callAsFunction(
            name: String,
            bazelPath: BazelPath,
            bazelPathType: BazelPathType,
            transitiveBazelPaths: [BazelPath],
            identifierForBazelPaths: String? = nil
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*name:*/ name,
                /*bazelPath:*/ bazelPath,
                /*bazelPathType:*/ bazelPathType,
                /*transitiveBazelPaths:*/ transitiveBazelPaths,
                /*identifierForBazelPaths:*/ identifierForBazelPaths,
                /*createFileElement:*/ createFileElement
            )
        }
    }
}

// MARK: - CreateFile.Callable

extension ElementCreator.CreateFile {
    typealias Callable = (
        _ name: String,
        _ bazelPath: BazelPath,
        _ bazelPathType: BazelPathType,
        _ transitiveBazelPaths: [BazelPath],
        _ identifierForBazelPaths: String?,
        _ createFileElement: ElementCreator.CreateFileElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        name: String,
        bazelPath: BazelPath,
        bazelPathType: BazelPathType,
        transitiveBazelPaths: [BazelPath],
        identifierForBazelPaths: String?,
        createFileElement: ElementCreator.CreateFileElement
    ) -> GroupChild.ElementAndChildren {
        let (
            element,
            resolvedRepository
        ) = createFileElement(
            name: name,
            ext: name.extension(),
            bazelPath: bazelPath,
            bazelPathType: bazelPathType
        )

        let bazelPaths = transitiveBazelPaths + [bazelPath]
        let identifierForBazelPaths =
            identifierForBazelPaths ?? element.object.identifier

        return GroupChild.ElementAndChildren(
            element: element,
            transitiveObjects: [element.object],
            bazelPathAndIdentifiers: bazelPaths
                .map { ($0, identifierForBazelPaths) },
            knownRegions: [],
            resolvedRepositories: resolvedRepository.map { [$0] } ?? []
        )
    }
}

private extension String {
    func `extension`() -> String? {
        guard let extIndex = lastIndex(of: ".") else {
            return nil
        }
        return String(self[index(after: extIndex)..<endIndex])
    }
}
