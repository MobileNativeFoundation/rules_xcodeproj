import PBXProj

extension Generator {
    struct CalculateTargetsPartial {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXProject.targets` partial.
        func callAsFunction(identifiers: [String]) -> String {
            return callable(/*identifiers:*/ identifiers)
        }
    }
}

// MARK: - CalculateTargetsPartial.Callable

extension Generator.CalculateTargetsPartial {
    typealias Callable = (_ identifiers: [String]) -> String

    static func defaultCallable(identifiers: [String]) -> String {
        // The tabs for indenting are intentional
        return #"""
			targets = (
				\#(Identifiers.BazelDependencies.id),
\#(identifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
		};

"""#
    }
}
