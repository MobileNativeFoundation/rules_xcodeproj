/// Helps set identifiers for `PBXProj` elements.
///
/// Identifiers are unique 12 byte numbers encoded as 24 character hex strings.
/// Since the various `PBXProj` partial generators need to work independently
/// from each other, they need help to be able to generate unique identifiers.
/// `Identifiers` is used to generate these identifiers.
public enum Identifiers {
    public enum BazelDependencies {
        public static let id = #"""
0000000000000000000000FF /* BazelDependencies */
"""#
        public static let preBuildScript = #"""
0000000000000000000000FE /* Pre-build Run Script */
"""#
        public static let bazelBuild = #"""
0000000000000000000000FD /* Bazel Build */
"""#
        public static let createSwiftDebugSettings = #"""
0000000000000000000000FC /* Create swift_debug_settings.py */
"""#
        public static let postBuildScript = #"""
0000000000000000000000FB /* Post-build Run Script */
"""#
        public static let buildConfigurationList = #"""
0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */
"""#

        /// Calculates the identifier for one of `BazelDependencies`'s
        /// `XCBBuildConfiguration`s.
        ///
        /// The identifiers start at `0000000000000000000000F9` and decrease
        /// down to a minimum of `000000000000000000000080`. This is because the
        /// other `Identifiers.BazelDependencies` values use the range
        /// `0000000000000000000000FA`...`0000000000000000000000FF`, and
        /// `Identifiers.Project.buildConfiguration` uses the range
        /// `000000000000000000000005`...`00000000000000000000007E`.
        ///
        /// - Precondition: `index` must be in the range `0...121`.
        public static func buildConfiguration(
            _ name: String,
            index: UInt8
        ) -> String {
            precondition(index <= 121, "`index` must be in the range `0...121`")
            return #"""
0000000000000000000000\#(String(0xF9 - index, radix: 16, uppercase: true)) \#
/* \#(name) */
"""#
        }
    }

    public enum FilesAndGroups {
        public static func mainGroup(_ path: String) -> String {
            return #"000000000000000000000003 /* \#(path) */"#
        }

        public static let productsGroup = #"""
000000000000000000000004 /* Products */
"""#
    }

    public enum Project {
        public static let id = #"000000000000000000000001 /* Project object */"#
        public static let buildConfigurationList = #"""
000000000000000000000002 /* Build configuration list for PBXProject */
"""#

        /// Calculates the identifier for one of the `PBXProject`
        /// `XCBBuildConfiguration`s.
        ///
        /// The identifiers start at `000000000000000000000005` and increase
        /// up to a maximum of `00000000000000000000007E`. This is because the
        /// other `Identifiers.Project` and `Identifiers.FilesAndGroups` values
        /// use the range
        /// `000000000000000000000001`...`000000000000000000000004`, and
        /// `Identifiers.BazelDependencies.buildConfiguration` uses the range
        /// `000000000000000000000080`...`0000000000000000000000F9`.
        ///
        /// - Precondition: `index` must be in the range `0...121`.
        public static func buildConfiguration(
            _ name: String,
            index: UInt8
        ) -> String {
            precondition(index <= 121, "`index` must be in the range `0...121`")
            return #"""
0000000000000000000000\#(String(format: "%02X", 0x05 + index)) \#
/* \#(name) */
"""#
        }
    }
}
