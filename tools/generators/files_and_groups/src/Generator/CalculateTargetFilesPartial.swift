import PBXProj

extension Generator {
    struct CalculateTargetFilesPartial {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXBuildFile`s and product `PBXFileReference`s
        /// partial.
        func callAsFunction(objects: [TargetFileObject]) -> String {
            return callable(/*objects:*/ objects)
        }
    }
}

// MARK: - CalculateTargetFilesPartial.Callable

extension Generator.CalculateTargetFilesPartial {
    typealias Callable = (
        _ objects: [TargetFileObject]
    ) -> String

    static func defaultCallable(
        objects: [TargetFileObject]
    ) -> String {
        var buildFiles: [Object] = []
        var productIdentifiers: [(
            subIdentifier: Identifiers.BuildFiles.SubIdentifier,
            identifier: String
        )] = []
        for targetFileObject in objects {
            switch targetFileObject {
            case .buildFile(let object):
                buildFiles.append(object)
            case .product(let subIdentifier, let identifier):
                productIdentifiers.append((subIdentifier, identifier))
            }
        }

        return #"""
\#(buildFiles.map { "\t\t\($0.identifier) = \($0.content);\n" }.joined())\#
		\#(Identifiers.FilesAndGroups.productsGroup) = {
			isa = PBXGroup;
			children = (
\#(
    productIdentifiers
        .sorted { lhs, rhs in
            let nameCompare = lhs.subIdentifier.path.path
                .localizedStandardCompare(rhs.subIdentifier.path.path)
            guard nameCompare == .orderedSame else {
                return nameCompare == .orderedAscending
            }
            return lhs.identifier < rhs.identifier
        }
        .map { "\t\t\t\t\($0.identifier),\n" }
        .joined()
)\#
			);
			name = Products;
			sourceTree = "<group>";
		};

"""#
    }
}
