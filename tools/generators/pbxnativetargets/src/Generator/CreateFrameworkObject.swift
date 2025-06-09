import PBXProj

extension Generator {
    struct CreateFrameworkObject {
        private let callable: Callable
        private static var existingFrameworkPaths = [BazelPath]()

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a `PBXBuildFile` element.
        func callAsFunction(
            frameworkPath: BazelPath,
            subIdentifier: Identifiers.BuildFiles.SubIdentifier
        ) -> Object {
            return callable(
                /*frameworkPath:*/ frameworkPath,
                /*subIdentifier:*/ subIdentifier
            )
        }
    }
}

// MARK: - CreateProductObject.Callable

extension Generator.CreateFrameworkObject {
    typealias Callable = (
        _ frameworkPath: BazelPath,
        _ subIdentifier: Identifiers.BuildFiles.SubIdentifier
    ) -> Object

    static func defaultCallable(
        frameworkPath: BazelPath,
        subIdentifier: Identifiers.BuildFiles.SubIdentifier
    ) -> Object {
        let content = #"""
{isa = PBXFileReference; lastKnownFileType = archive.ar; name = "\#(frameworkPath.path.split(separator: "/").last!)"; path = "\#(frameworkPath.path)"; sourceTree = "<group>"; }
"""#

        return Object(
            identifier: Identifiers.BuildFiles.id(subIdentifier: subIdentifier),
            content: content
        )
    }
}
