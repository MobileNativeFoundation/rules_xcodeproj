import PBXProj

extension Generator {
    struct CreateFrameworkBuildFileObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a `PBXBuildFile` element.
        func callAsFunction(
            frameworkSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
            subIdentifier: Identifiers.BuildFiles.SubIdentifier
        ) -> Object {
            return callable(
                /*frameworkSubIdentifier:*/ frameworkSubIdentifier,
                /*subIdentifier:*/ subIdentifier
            )
        }
    }
}

// MARK: - CreateFrameworkBuildFileObject.Callable

extension Generator.CreateFrameworkBuildFileObject {
    typealias Callable = (
        _ frameworkSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        _ subIdentifier: Identifiers.BuildFiles.SubIdentifier
    ) -> Object

    static func defaultCallable(
        frameworkSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        subIdentifier: Identifiers.BuildFiles.SubIdentifier
    ) -> Object {
        let fileRef = Identifiers.BuildFiles
            .id(subIdentifier: frameworkSubIdentifier)
        let content = #"""
{isa = PBXBuildFile; fileRef = \#(fileRef); }
"""#

        return Object(
            identifier: Identifiers.BuildFiles.id(subIdentifier: subIdentifier),
            content: content
        )
    }
}
