import PBXProj

extension ElementCreator {
    class CreateIdentifier {
        private var hashCache: Set<String> = []

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Identifiers.FilesAndGroups.element
        ) {
            self.callable = callable
        }

        /// See `Identifiers.FilesAndGroups.element` for details.
        func callAsFunction(
            path: String,
            type: Identifiers.FilesAndGroups.ElementType
        ) -> String {
            return callable(
                path,
                /*type:*/ type,
                /*hashCache:*/ &hashCache
            )
        }
    }
}

// MARK: - CreateIdentifier.Callable

extension ElementCreator.CreateIdentifier {
    typealias Callable = (
        _ path: String,
        _ type: Identifiers.FilesAndGroups.ElementType,
        _ hashCache: inout Set<String>
    ) -> String
}
