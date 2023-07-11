import PBXProj

extension Generator {
    struct CalculateSingleTargetAttributes {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates a `PBXProject.targets` element.
        func callAsFunction(
            createdOnToolsVersion: String,
            testHostIdentifier: String?
        ) -> String {
            return callable(
                /*createdOnToolsVersion:*/ createdOnToolsVersion,
                /*testHostIdentifier:*/ testHostIdentifier
            )
        }
    }
}

// MARK: - CalculateSingleTargetAttributes.Callable

extension Generator.CalculateSingleTargetAttributes {
    typealias Callable = (
        _ createdOnToolsVersion: String,
        _ testHostIdentifier: String?
    ) -> String

    static func defaultCallable(
        createdOnToolsVersion: String,
        testHostIdentifier: String?
    ) -> String {
        let testTargetID: String
        if let testHostIdentifier = testHostIdentifier {
            testTargetID = #"""
						TestTargetID = \#(testHostIdentifier);

"""#
        } else {
            testTargetID = ""
        }

        // The tabs for indenting are intentional
        return #"""
{
						CreatedOnToolsVersion = \#(createdOnToolsVersion);
						LastSwiftMigration = 9999;
\#(testTargetID)\#
					}
"""#
    }
}
