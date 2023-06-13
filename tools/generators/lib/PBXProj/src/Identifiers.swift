import CryptoKit

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
        /// down to a minimum of `000000000000000000000081`. This is because the
        /// other `Identifiers.BazelDependencies` values use the range
        /// `0000000000000000000000FA`...`0000000000000000000000FF`, and
        /// `Identifiers.Project.buildConfiguration` uses the range
        /// `000000000000000000000008`...`000000000000000000000080`.
        ///
        /// - Precondition: `index` must be in the range `0...120`.
        public static func buildConfiguration(
            _ name: String,
            index: UInt8
        ) -> String {
            precondition(index <= 120, "`index` must be in the range `0...120`")
            return #"""
0000000000000000000000\#(String(0xF9 - index, radix: 16, uppercase: true)) \#
/* \#(name) */
"""#
        }
    }

    public enum FilesAndGroups {
        /// The logical type of the element being identified.
        public enum ElementType: String {
            /// A normal `PBXFileReference`.
            case fileReference = "0"

            /// A `PBXGroup`.
            case group = "1"

            /// A `PBXVariantGroup` or child `PBXFileReference`.
            case localized = "2"

            /// A `XCVersionGroup` or child `PBXFileReference`.
            case coreData = "3"
        }

        public static func mainGroup(_ path: String) -> String {
            return #"000000000000000000000003 /* \#(path) */"#
        }

        public static let bazelExternalRepositoriesGroup = #"""
000000000000000000000006 /* Bazel External Repositories */
"""#
        public static let bazelGeneratedFilesGroup = #"""
000000000000000000000007 /* Bazel Generated Files */
"""#
        public static let frameworksGroup = #"""
000000000000000000000005 /* Frameworks */
"""#
        public static let productsGroup = #"""
000000000000000000000004 /* Products */
"""#

        /// Calculates the identifier for a file or group element at `path`.
        ///
        /// - Note: The order that this is called matters. If two `path + type`
        ///   hash to the same value, the second one will have a new hash
        ///   generated to guarantee it is unique.
        ///
        /// - Parameters:
        ///   - path: The file path for the version group.
        ///   - type: The type of path being identified.
        ///   - hashCache: A cache that will be used to guarantee that the
        ///     identifier returned is unique.
        public static func element(
            _ path: String,
            type: ElementType,
            hashCache: inout Set<String>
        ) -> String {
            let hash = elementHash(path + type.rawValue, hashCache: &hashCache)
            return #"FF\#(hash) /* \#(path) */"#
        }

        /// Calculates a unique hash for the path encoded in `hashable`. The
        /// hash needs to be unique among all of the values in `hashCache`,
        /// because two different `hashable` might hash to the same value, and
        /// the hash is used as part of a unique identifier, so we can't have
        /// clashes.
        private static func elementHash(
            _ hashable: String,
            hashCache: inout Set<String>
        ) -> String {
            var hash: String
            var retryCount = 0
            repeat {
                hash = elementHash(hashable, retryCount: retryCount)
                retryCount += 1
            } while hashCache.contains(hash)

            hashCache.insert(hash)

            return hash
        }

        private static func elementHash(
            _ path: String,
            retryCount: Int
        ) -> String {
            let content: String
            if retryCount == 0 {
                content = path
            } else {
                content = "\(path)\0\(retryCount)"
            }

            let digest = Insecure.MD5.hash(data: content.data(using: .utf8)!)
            return digest
                // Xcode identifiers are 24 characters. We are using 2
                // characters at the front for "FF". That leaves 22 characters
                // that we can use. MD5 digests are 16 bytes (32 characters)
                // long. So we need to truncate it to fit within the remaining
                // 22 characters (by dropping 5 bytes). We choose the front 22
                // because are the most unique.
                .dropLast(5)
                .map { String(format: "%02X", $0) }
                .joined()
        }
    }

    public enum Project {
        public static let id = #"000000000000000000000001 /* Project object */"#
        public static let buildConfigurationList = #"""
000000000000000000000002 /* Build configuration list for PBXProject */
"""#

        /// Calculates the identifier for one of the `PBXProject`
        /// `XCBBuildConfiguration`s.
        ///
        /// The identifiers start at `000000000000000000000009` and increase
        /// up to a maximum of `000000000000000000000080`. This is because the
        /// other `Identifiers.Project` and `Identifiers.FilesAndGroups` values
        /// use the range
        /// `000000000000000000000001`...`000000000000000000000008`, and
        /// `Identifiers.BazelDependencies.buildConfiguration` uses the range
        /// `000000000000000000000081`...`0000000000000000000000F9`.
        ///
        /// - Precondition: `index` must be in the range `0...120`.
        public static func buildConfiguration(
            _ name: String,
            index: UInt8
        ) -> String {
            precondition(index <= 120, "`index` must be in the range `0...120`")
            return #"""
0000000000000000000000\#(String(format: "%02X", 0x08 + index)) \#
/* \#(name) */
"""#
        }
    }
}
