import PBXProj

extension Generator {
    struct CalculateTargetAttributesPartial {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXProject.attributes.TargetAttributes` partial.
        func callAsFunction(objects: [Object]) -> String {
            return callable(/*objects:*/ objects)
        }
    }
}

// MARK: - CalculateTargetAttributesPartial.Callable

extension Generator.CalculateTargetAttributesPartial {
    typealias Callable = (_ objects: [Object]) -> String

    static func defaultCallable(objects: [Object]) -> String {
        // Xcode writes dictionary keys sorted, so we do as well. This allows
        // the `project.pbxproj` to be byte-identical to what Xcode writes,
        // preventing Xcode from rewriting it.
        let objects = objects.sorted { $0.identifier < $1.identifier }

        // The tabs for indenting are intentional
        return #"""
				TargetAttributes = {
\#(objects.map { "\t\t\t\t\t\($0.identifier) = \($0.content);\n" }.joined())\#
				};
			};

"""#
    }
}
