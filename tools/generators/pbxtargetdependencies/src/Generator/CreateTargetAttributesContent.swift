import PBXProj

extension Generator {
    struct CreateTargetAttributesContent {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates a `PBXProject.targets` object content.
        func callAsFunction(
            createdOnToolsVersion: String,
            testHostIdentifierWithoutComment: String?
        ) -> String {
            return callable(
                /*createdOnToolsVersion:*/ createdOnToolsVersion,
                /*testHostIdentifierWithoutComment:*/
                    testHostIdentifierWithoutComment
            )
        }
    }
}

// MARK: - CreateTargetAttributesContent.Callable

extension Generator.CreateTargetAttributesContent {
    typealias Callable = (
        _ createdOnToolsVersion: String,
        _ testHostIdentifierWithoutComment: String?
    ) -> String

    static func defaultCallable(
        createdOnToolsVersion: String,
        testHostIdentifierWithoutComment: String?
    ) -> String {
        let testTargetID: String
        if let testHostIdentifierWithoutComment {
            testTargetID = #"""
						TestTargetID = \#(testHostIdentifierWithoutComment);

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
