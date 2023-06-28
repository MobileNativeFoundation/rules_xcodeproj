import CryptoKit

/// Helps set identifiers for `PBXProj` elements.
///
/// Identifiers are unique 12 byte numbers encoded as 24 character hex strings.
/// Since the various `PBXProj` partial generators need to work independently
/// from each other, they need help to be able to generate unique identifiers.
/// `Identifiers` is used to generate these identifiers.
///
/// The identifiers aren't all hashes. Grouping information is also encoded into
/// them. The first two characters indicate that it's a global element (`FF`), a
/// file or group element (`FE`), or a generator shard (`00`-`FD`).
///
/// - Global elements (which start with `FF`) are then classified as belonging
///   to the project as a whole (`00`) or the `BazelDependencies` target
///   (`01`). For both of them, their associated elements (e.g. configuration
///   list, build phases, etc.) use
///   `00000000000000000000`-`000000000000000000FF`, and their configurations
///   (e.g. "Debug", "Release", etc.) use
///   `00000000000000000100`-`000000000000000001FF`.
///
/// - Files and groups (which start with `FE`) use the remaining characters
///   (`0000000000000000000000`-`FFFFFFFFFFFFFFFFFFFFFF`).
///
/// - Generator shards (which start with `00`-`FD`) use the next two
///   characters to indicate a target and its associated elements (`00`), a
///   target dependency (`01`), a container item proxy (`02`), or a build file
///   (`FF`).
///
///   - Targets (which start with `xx00`) use the next eight characters to
///     identify a target (`00000000`-`FFFFFFFF`, called a target
///     sub-identifier). Then it uses `000000000000`-`0000000000FF` for its
///     associated elements (e.g. configuration list, build phases, etc.), and
///     `000000000100`-`0000000001FF` for its configurations (e.g. "Debug",
///     "Release", etc.).
///
///   - Target dependencies (which start with `xx01`) and container item
///     proxies (which start with `xx02`) use the next eight characters to
///     identify the dependent target with a target sub-identifier
///     (`00000000`-`FFFFFFFF`). Then it uses the remaining characters to
///     identify the dependency target with the shard and target sub-identifier
///     (`xx0000000000`-`xx00FFFFFFFF`).
///
///   - Build files (which start with `xxFF`) use the remaining
///     characters (`00000000000000000000`-`FFFFFFFFFFFFFFFFFFFF`).
public enum Identifiers {
    public enum BazelDependencies {
        public static let id = #"""
FF0100000000000000000001 /* BazelDependencies */
"""#
        public static let buildConfigurationList = #"""
FF0100000000000000000002 /* Build configuration list for PBXAggregateTarget "BazelDependencies" */
"""#
        public static let preBuildScript = #"""
FF0100000000000000000003 /* Pre-build Run Script */
"""#
        public static let bazelBuild = #"""
FF0100000000000000000004 /* Bazel Build */
"""#
        public static let createSwiftDebugSettings = #"""
FF0100000000000000000005 /* Create swift_debug_settings.py */
"""#
        public static let postBuildScript = #"""
FF0100000000000000000006 /* Post-build Run Script */
"""#

        /// Calculates the identifier for one of `BazelDependencies`'s
        /// `XCBBuildConfiguration`s.
        ///
        /// Identifiers start at `FF0100000000000000000100` and increase
        /// to `FF01000000000000000001FF`.
        public static func buildConfiguration(
            _ name: String,
            index: UInt8
        ) -> String {
            return #"""
FF01000000000000000001\#(String(format: "%02X", index)) \#
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
            return #"FF0000000000000000000003 /* \#(path) */"#
        }

        public static let bazelExternalRepositoriesGroup = #"""
FF0000000000000000000006 /* Bazel External Repositories */
"""#
        public static let bazelGeneratedFilesGroup = #"""
FF0000000000000000000007 /* Bazel Generated Files */
"""#
        public static let frameworksGroup = #"""
FF0000000000000000000005 /* Frameworks */
"""#
        public static let productsGroup = #"""
FF0000000000000000000004 /* Products */
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
            return #"FE\#(hash) /* \#(path) */"#
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
            _ hashable: String,
            retryCount: Int
        ) -> String {
            let content: String
            if retryCount == 0 {
                content = hashable
            } else {
                content = "\(hashable)\0\(retryCount)"
            }

            let digest = Insecure.MD5.hash(data: content.data(using: .utf8)!)
            return digest
                // Xcode identifiers are 24 characters. We are using 2
                // characters at the front for "FE". That leaves 22 characters
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
        public static let id = #"FF0000000000000000000001 /* Project object */"#
        public static let buildConfigurationList = #"""
FF0000000000000000000002 /* Build configuration list for PBXProject */
"""#

        /// Calculates the identifier for one of the `PBXProject`
        /// `XCBBuildConfiguration`s.
        ///
        /// Identifiers start at `FF0000000000000000000100` and increase
        /// to `FF00000000000000000001FF`.
        public static func buildConfiguration(
            _ name: String,
            index: UInt8
        ) -> String {
            return #"""
FF00000000000000000001\#(String(format: "%02X", index)) \#
/* \#(name) */
"""#
        }
    }
}
