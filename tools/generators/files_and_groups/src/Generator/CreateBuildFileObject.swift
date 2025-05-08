import PBXProj

extension Generator {
    struct CreateBuildFileObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a `PBXBuildFile` element.
        func callAsFunction(
            subIdentifier: Identifiers.BuildFiles.SubIdentifier,
            fileIdentifier: String
        ) -> Object {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*fileIdentifier:*/ fileIdentifier
            )
        }
    }
}

// MARK: - CreateBuildFileObject.Callable

extension Generator.CreateBuildFileObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.BuildFiles.SubIdentifier,
        _ fileIdentifier: String
    ) -> Object

    static func defaultCallable(
        subIdentifier: Identifiers.BuildFiles.SubIdentifier,
        fileIdentifier: String
    ) -> Object {
        let settings: String
        switch subIdentifier.type {
        case .nonArcSource:
            settings = #"settings = {COMPILER_FLAGS = "-fno-objc-arc"; }; "#
        case .compileStub, .source:
            settings = ""
        case .product, .watchKitExtension, .framework:
            // Handled in `CreateProductBuildFileObject` and
            // `CreateProductObject`
            preconditionFailure()
        }

        let content = #"""
{isa = PBXBuildFile; fileRef = \#(fileIdentifier); \#(settings)}
"""#

        return Object(
            identifier: Identifiers.BuildFiles.id(subIdentifier: subIdentifier),
            content: content
        )
    }
}
