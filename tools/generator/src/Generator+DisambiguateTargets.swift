import CryptoKit
import XcodeProj

/// A `struct` containing values for a target that need to be unique in the eyes
/// of Xcode, as well as the target itself.
///
/// Xcode requires that certain properties of targets are unique, such as name,
/// the `TARGET_NAME` and `PRODUCT_MODULE_NAME` build settings, etc. This class
/// collects information on all of the targets and calculates unique values for
/// each one. If the values are user facing (i.e. the target name), then they
/// are formatted in a readable way.
struct DisambiguatedTarget: Equatable {
    let name: String
    let nameBuildSetting: String
    let target: Target
}

extension Generator {
    /// Returns a mapping of target ids to `DisambiguatedTarget`s.
    static func disambiguateTargets(
        _ targets: [TargetID: Target]
    ) -> [TargetID: DisambiguatedTarget] {
        // Gather all information needed to distinguish the targets
        var components: [String: TargetComponents] = [:]
        var targetHashes = Dictionary<TargetID, String>(
            minimumCapacity: targets.count
        )
        for (id, target) in targets {
            components[target.name, default: .init()].add(target: target)
            targetHashes[id] = id.rawValue.sha1Hash()
        }

        // And then distinguish them
        var uniqueValues = Dictionary<TargetID, DisambiguatedTarget>(
            minimumCapacity: targets.count
        )
        for (id, target) in targets {
            uniqueValues[id] = DisambiguatedTarget(
                name: components[target.name]!.uniqueName(target: target),
                nameBuildSetting: "\(target.name)-\(targetHashes[id]!)",
                target: target
            )
        }

        return uniqueValues
    }
}

struct TargetComponents {
    /// Maps target product type names to `ProductTypeComponents`.
    ///
    /// For each product type name among the `Target`s passed to `add(target:)`,
    /// there will be an entry in `productTypes`.
    /// `ProductTypeComponents.add(target)` will have been called for each
    /// `Target`.
    private var productTypes: [String: ProductTypeComponents] = [:]

    /// Adds another `Target` into consideration for `uniqueName()`.
    mutating func add(target: Target) {
        productTypes[target.product.type.prettyName, default: .init()]
            .add(target: target)
    }

    /// Returns a unique name for the given `Target`.
    ///
    /// - Precondition: All targets have been added with `add(target:)` before
    ///   this is called.
    func uniqueName(target: Target) -> String {
        // TODO: Handle same name at different parts in the build graph?
        // This shouldn't happen for modules (though maybe with the new renaming
        // stuff in Swift it can?), but could for bundles.
        let distinguishers = productTypes[target.product.type.prettyName]!.distinguishers(
            target: target,
            forceDistinguisher: productTypes.count > 1
        )

        // Returns "Name (a) (b)" when `distinguishers` is `["a", "b"]`, and
        // returns "Name" when `distinguishers` is empty.
        return ([target.name] + distinguishers.map { "(\($0))" })
            .joined(separator: " ")
    }
}

/// `ProductTypeComponents` collects properties of `Target`s for a given
/// product type and provides the capability to generate a set of
/// distinguisher strings for any of the `Target`s it collected properties from.
struct ProductTypeComponents {
    /// Maps operating system names to `OperatingSystemComponents`.
    ///
    /// For each operating system name among the `Target`s passed to
    /// `add(target:)`, there will be an entry in `oses`.
    /// `OperatingSystemComponents.add(target)` will have been called for each
    /// `Target`.
    var oses: [String: OperatingSystemComponents] = [:]

    /// Adds another `Target` into consideration for `distinguishers()`.
    mutating func add(target: Target) {
        oses[target.platform.os, default: .init()].add(target: target)
    }

    /// Generates an array of user-facing strings that, along with a target
    /// name, uniquely distinguishes it from targets with the same non-
    /// distinguished name.
    ///
    /// - Precondition: All targets have been added with `add(target:)` before
    ///   this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - forceDistinguisher: If `true`, the product type will be part of the
    ///     array returned.
    ///
    /// - Returns: `nil` if no distinguisher is needed.
    func distinguishers(
        target: Target,
        forceDistinguisher: Bool
    ) -> [String] {
        var distinguishers: [String] = []

        if forceDistinguisher {
            distinguishers.append(target.product.type.prettyName)
        }

        if let osDistinguisher = oses[target.platform.os]!.distinguisher(
            target: target,
            forceDistinguisher: oses.count > 1
        ) {
            distinguishers.append(osDistinguisher)
        }

        return distinguishers
    }
}

/// `OperatingSystemComponents` collects properties of `Target`s for a given
/// operating system name and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct OperatingSystemComponents {
    /// The set of architectures among the targets passed to `add(target:)`.
    private var archs: Set<String> = []

    /// The set of minimum OS versions among the targets passed to
    /// `add(target:)`.
    private var minimumVersions: Set<String> = []

    /// The set of environments (e.g. "Simulator") among the targets passed to
    /// `add(target:)`.
    private var environments: Set<String?> = []

    /// A count of `Target.distinguisherKey`s seen in `add(target:)`.
    ///
    /// If the count for a `distinguisherKey` is greater than one, then targets
    /// that have that key will have their configuration returned from
    /// `distinguisher()` instead of a string containing architecture, OS, etc.
    private var distinguisherKeys: [String: Int] = [:]

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target) {
        let platform = target.platform

        archs.insert(platform.arch)
        minimumVersions.insert(platform.minimumOsVersion)
        environments.insert(platform.environment)
        distinguisherKeys[target.distinguisherKey, default: 0] += 1
    }

    /// Potentially generates a user-facing string that, along with a target
    /// name, uniquely distinguishes it from targets with the same non-
    /// distinguished name.
    ///
    /// - Precondition: All targets have been added with `add(target:)` before
    ///   this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - forceDistinguisher: If `true`, the operating system name will be
    ///     part of the string returned.
    ///
    /// - Returns: `nil` if no distinguisher is needed.
    func distinguisher(target: Target, forceDistinguisher: Bool) -> String? {
        let platform = target.platform

        if distinguisherKeys[target.distinguisherKey]! > 1 {
            // The target name would be ambiguous, even with our distinguisher
            // components. We will show a shorted configuration hash instead,
            // which will be unique.
            var components: [String] = []

            if forceDistinguisher {
                components.append(platform.os)
            }

            components.append(Target.prettyConfiguration(target.configuration))

            return components.joined(separator: ", ")
        } else {
            var components: [String] = []

            if archs.count > 1 {
                components.append(platform.arch)
            }
            if forceDistinguisher || minimumVersions.count > 1 {
                components.append(platform.os)
            }
            if minimumVersions.count > 1 {
                components.append(platform.minimumOsVersion)
            }
            if environments.count > 1 {
                components.append(platform.environment ?? "Device")
            }

            return components.isEmpty ? nil : components.joined(separator: " ")
        }
    }
}

extension Target {
    /// Memoized configuration hashes.
    private static var configurationHashes: [String: String] = [:]

    /// Returns a user-facing string for a given configuration.
    static func prettyConfiguration(_ configuration: String) -> String {
        if let hash = configurationHashes[configuration] {
            return hash
        }

        let hash = String(configuration.sha1Hash().prefix(5))
        configurationHashes[configuration] = hash

        return hash
    }
}

private extension Target {
    /// A key that corresponds to the most-distinguished string that
    /// `OperatingSystemComponents.distinguisher()` can return for this
    /// `Target`.
    var distinguisherKey: String {
        // This doesn't need `platform.os`, as `OperatingSystemComponents` is
        // already segregated by operating system name.
        return [
            platform.arch,
            platform.minimumOsVersion,
            platform.environment ?? "Device"
        ].joined(separator: "-")
    }
}

private extension String {
    /// Computes a sha1 hash string for this `String`.
    func sha1Hash() -> String {
        return Insecure.SHA1
            .hash(data: data(using: .utf8)!)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
