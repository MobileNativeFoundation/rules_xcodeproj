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
        func callAsFunction(elements: [Element]) -> String {
            return callable(/*elements:*/ elements)
        }
    }
}

// MARK: - CalculateTargetAttributesPartial.Callable

extension Generator.CalculateTargetAttributesPartial {
    typealias Callable = (_ elements: [Element]) -> String

    static func defaultCallable(elements: [Element]) -> String {
        // The tabs for indenting are intentional
        return #"""
				TargetAttributes = {
\#(elements.map { "\t\t\t\t\t\($0.identifier) = \($0.content);\n" }.joined())\#
				};
			};

"""#
    }
}
