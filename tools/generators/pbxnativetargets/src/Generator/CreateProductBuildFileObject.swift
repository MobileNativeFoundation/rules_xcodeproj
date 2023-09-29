import PBXProj

extension Generator {
    struct CreateProductBuildFileObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a `PBXBuildFile` element.
        func callAsFunction(
            productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
            subIdentifier: Identifiers.BuildFiles.SubIdentifier
        ) -> Object {
            return callable(
                /*productSubIdentifier:*/ productSubIdentifier,
                /*subIdentifier:*/ subIdentifier
            )
        }
    }
}

// MARK: - CreateProductBuildFileObject.Callable

extension Generator.CreateProductBuildFileObject {
    typealias Callable = (
        _ productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        _ subIdentifier: Identifiers.BuildFiles.SubIdentifier
    ) -> Object

    static func defaultCallable(
        productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        subIdentifier: Identifiers.BuildFiles.SubIdentifier
    ) -> Object {
        let fileRef = Identifiers.BuildFiles
            .id(subIdentifier: productSubIdentifier)
        let content = #"""
{isa = PBXBuildFile; fileRef = \#(fileRef); settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; }
"""#

        return Object(
            identifier: Identifiers.BuildFiles.id(subIdentifier: subIdentifier),
            content: content
        )
    }
}
