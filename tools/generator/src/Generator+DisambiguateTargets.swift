import CryptoKit
import XcodeProj

/// A `struct` containing values for a target that need to be unique in the eyes
/// of Xcode, as well as the target itself.
///
/// Xcode requires that certain properties of targets are unique, such as name,
/// the `PRODUCT_MODULE_NAME` build setting, etc. This class collects
/// information on all of the targets and calculates unique values for each one.
/// If the values are user facing (i.e. the target name), then they are
/// formatted in a readable way.
struct DisambiguatedTarget: Equatable {
    let name: String
    let target: Target
}

struct DisambiguatedTargets: Equatable {
    let targets: [TargetID: DisambiguatedTarget]
}

extension Generator {
    static func disambiguateTargets(
        _ targets: [TargetID: Target]
    ) -> DisambiguatedTargets {
        // Gather all information needed to distinguish the targets
        var labelsByName: [String: Set<String>] = [:]
        var names: [String: TargetComponents] = [:]
        var labels: [String: TargetComponents] = [:]
        for target in targets.values {
            let normalizedName = target.normalizedName
            let normalizedLabel = target.normalizedLabel
            labelsByName[normalizedName, default: []].insert(normalizedLabel)
            names[normalizedName, default: .init()].add(target: target)
            labels[normalizedLabel, default: .init()].add(target: target)
        }

        // And then distinguish them
        var uniqueValues = Dictionary<TargetID, DisambiguatedTarget>(
            minimumCapacity: targets.count
        )
        for (id, target) in targets {
            let name: String
            let componentKey: String
            let components: [String: TargetComponents]
            let normalizedName = target.normalizedName
            if labelsByName[normalizedName]!.count == 1 {
                name = target.name
                componentKey = normalizedName
                components = names
            } else {
                name = target.label
                componentKey = target.normalizedLabel
                components = labels
            }

            uniqueValues[id] = DisambiguatedTarget(
                name: components[componentKey]!
                    .uniqueName(for: target, baseName: name),
                target: target
            )
        }

        return DisambiguatedTargets(
            targets: uniqueValues
        )
    }
}

struct TargetComponents {
    /// Maps target product type names to `ProductTypeComponents`.
    ///
    /// For each product type name among the `Target`s passed to `add(target:)`,
    /// there will be an entry in `productTypes`.
    /// `ProductTypeComponents.add(target:)` will have been called for each
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
    func uniqueName(for target: Target, baseName: String) -> String {
        // TODO: Handle same name at different parts in the build graph?
        // This shouldn't happen for modules (though maybe with the new renaming
        // stuff in Swift it can?), but could for bundles.
        let distinguishers = productTypes[target.product.type.prettyName]!
            .distinguishers(
                target: target,
                includeProductType: productTypes.count > 1
            )

        // Returns "Name (a) (b)" when `distinguishers` is `["a", "b"]`, and
        // returns "Name" when `distinguishers` is empty.
        return ([baseName] + distinguishers.map { "(\($0))" })
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
    /// `OperatingSystemComponents.add(target:)` will have been called for each
    /// `Target`.
    private var oses: [Platform.OS: OperatingSystemComponents] = [:]

    /// A count of `Target.distinguisherKey`s seen in `add(target:)`.
    ///
    /// If the count for a `distinguisherKey` is greater than one, then targets
    /// that have that key will have their configuration returned from
    /// `distinguisher()` instead of a string containing architecture, OS, etc.
    private var distinguisherKeys: [String: Int] = [:]

    /// Adds another `Target` into consideration for `distinguishers()`.
    mutating func add(target: Target) {
        oses[target.platform.os, default: .init()].add(target: target)
        distinguisherKeys[target.distinguisherKey, default: 0] += 1
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
    ///   - includeProductType: If `true`, the product type will be part of the
    ///     array returned.
    func distinguishers(
        target: Target,
        includeProductType: Bool
    ) -> [String] {
        var distinguishers: [String] = []

        if includeProductType {
            distinguishers.append(target.product.type.prettyName)
        }

        let includeOS = oses.count > 1

        guard !needsConfigurationDistinguishing(target: target) else {
            // The target name would be ambiguous, even with our distinguisher
            // components. We will show a shorted configuration hash instead,
            // which will be unique.
            if includeOS {
                distinguishers.append(
                    target.platform.os.prettyName
                )
            }

            distinguishers.append(
                Target.prettyConfiguration(target.configuration)
            )

            return distinguishers
        }

        if let osDistinguisher = oses[target.platform.os]!.distinguisher(
            target: target,
            includeOS: includeOS
        ) {
            distinguishers.append(osDistinguisher)
        }

        return distinguishers
    }

    private func needsConfigurationDistinguishing(target: Target) -> Bool {
        return distinguisherKeys[target.distinguisherKey]! > 1
    }
}

/// `OperatingSystemComponents` collects properties of `Target`s for a given
/// operating system name and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct OperatingSystemComponents {
    /// For operating system minimum versions among the `Target`s passed to
    /// `add(target:)`, there will be an entry in `minimumVersions`.
    /// `VersionedOperatingSystemComponents.add(target:)` will have been called
    /// for each `Target`.
    private var minimumVersions: [String: VersionedOperatingSystemComponents] =
        [:]

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target) {
        let minimumVersion = target.platform.minimumOsVersion

        minimumVersions[minimumVersion, default: .init()].add(target: target)
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
    ///   - includeOS: If `true`, the operating system name will be part of the
    ///     string returned.
    ///
    /// - Returns: `nil` if no distinguisher is needed.
    func distinguisher(target: Target, includeOS: Bool) -> String? {
        var components: [String] = []
        let platform = target.platform

        let includeVersion = minimumVersions.count > 1

        let versionDistinguisher = minimumVersions[
            target.platform.minimumOsVersion
        ]!.distinguisher(
            target: target,
            includeVersion: includeVersion
        )

        if let prefix = versionDistinguisher.prefix {
            components.append(prefix)
        }

        if includeOS || includeVersion {
            components.append(platform.os.prettyName)
        }

        components.append(contentsOf: versionDistinguisher.suffix)

        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}

/// `VersionedOperatingSystemComponents` collects properties of `Target`s for a
/// given operating system version and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct VersionedOperatingSystemComponents {
    struct Distinguisher {
        let prefix: String?
        let suffix: [String]
    }

    /// Maps platform environments (e.g. "Simulator") to
    /// `EnvironmentSystemComponents`.
    ///
    /// For operating system minimum versions among the `Target`s passed to
    /// `add(target:)`, there will be an entry in `environments`.
    /// `EnvironmentSystemComponents.add(target:)` will have been called for
    /// each `Target`.
    private var environments: [String: EnvironmentSystemComponents] = [:]

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target) {
        environments[target.platform.environment ?? "Device", default: .init()]
            .add(target: target)
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with `add(target:)` before
    ///   this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - includeVersion: If `true`, the operating system version will be
    ///     part of the `Distinguisher` returned.
    func distinguisher(
        target: Target,
        includeVersion: Bool
    ) -> Distinguisher {
        let platform = target.platform

        let environmentDistinguisher = environments[
                platform.environment ?? "Device"
        ]!.distinguisher(
            target: target,
            includeEnvironment: environments.count > 1
        )

        let prefix = environmentDistinguisher.prefix

        var suffix: [String] = []

        if includeVersion {
            suffix.append(platform.minimumOsVersion)
        }
        if let environmentSuffix = environmentDistinguisher.suffix {
            suffix.append(environmentSuffix)
        }

        return Distinguisher(prefix: prefix, suffix: suffix)
    }
}

/// `EnvironmentSystemComponents` collects properties of `Target`s for a
/// given platform environment and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct EnvironmentSystemComponents {
    struct Distinguisher {
        let prefix: String?
        let suffix: String?
    }

    /// The set of architectures among the targets passed to `add(target:)`.
    private var archs: Set<String> = []

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target) {
        archs.insert(target.platform.arch)
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with `add(target:)`
    ///   before this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - includeEnvironment: If `true`, the operating system version will be
    ///     part of the `Distinguisher` returned.
    func distinguisher(
        target: Target,
        includeEnvironment: Bool
    ) -> Distinguisher {
        let platform = target.platform

        let prefix = archs.count > 1 ? platform.arch : nil
        let suffix = includeEnvironment ? platform.environment ?? "Device" : nil

        return Distinguisher(prefix: prefix, suffix: suffix)
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
    /// `ProductTypeComponents.distinguisher()` can return for this
    /// `Target`.
    var distinguisherKey: String {
        return [
            platform.arch,
            platform.os.rawValue,
            platform.minimumOsVersion,
            platform.environment ?? "Device",
        ].joined(separator: "-")
    }
}

private extension Platform.OS {
    var prettyName: String {
        switch self {
        case .macOS: return "macOS"
        case .iOS: return "iOS"
        case .watchOS: return "watchOS"
        case .tvOS: return "tvOS"
        }
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
