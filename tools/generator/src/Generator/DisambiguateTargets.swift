import CryptoKit
import OrderedCollections
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
    let target: ConsolidatedTarget
}

struct DisambiguatedTargets: Equatable {
    let keys: [TargetID: ConsolidatedTarget.Key]
    let targets: [ConsolidatedTarget.Key: DisambiguatedTarget]
}

extension Generator {
    static func disambiguateTargets(
        _ consolidatedTargets: ConsolidatedTargets
    ) -> DisambiguatedTargets {
        let targets = consolidatedTargets.targets

        // Gather all information needed to distinguish the targets
        var labelsByName: [String: Set<String>] = [:]
        var names: [String: TargetComponents] = [:]
        var labels: [String: TargetComponents] = [:]
        for (key, target) in targets {
            let normalizedName = target.normalizedName
            let normalizedLabel = target.normalizedLabel
            labelsByName[normalizedName, default: []].insert(normalizedLabel)
            names[normalizedName, default: .init()]
                .add(target: target, key: key)
            labels[normalizedLabel, default: .init()]
                .add(target: target, key: key)
        }

        // And then distinguish them
        var uniqueValues = [
            ConsolidatedTarget.Key: DisambiguatedTarget,
        ](minimumCapacity: targets.count)
        for (key, target) in targets {
            let name: String
            let componentKey: String
            let components: [String: TargetComponents]
            let normalizedName = target.normalizedName
            if labelsByName[normalizedName]!.count == 1 {
                name = target.name
                componentKey = normalizedName
                components = names
            } else {
                name = "\(target.label)"
                componentKey = target.normalizedLabel
                components = labels
            }

            uniqueValues[key] = DisambiguatedTarget(
                name: components[componentKey]!
                    .uniqueName(for: target, key: key, baseName: name),
                target: target
            )
        }

        return DisambiguatedTargets(
            keys: consolidatedTargets.keys,
            targets: uniqueValues
        )
    }
}

struct TargetComponents {
    /// The set of `ConsolidatedTarget.Key`s among the targets passed to
    /// `add(target:key:)`.
    private var targetKeys: Set<ConsolidatedTarget.Key> = []

    /// Maps target product type names to `ProductTypeComponents`.
    ///
    /// For each product type name among the `ConsolidatedTarget`s passed to
    /// `add(target:key:)`, there will be an entry in `productTypes`.
    /// `ProductTypeComponents.add(target:key:)` will have been called for each
    /// `ConsolidatedTarget`.
    private var productTypes: [String: ProductTypeComponents] = [:]

    /// Adds another `Target` into consideration for `uniqueName()`.
    mutating func add(target: ConsolidatedTarget, key: ConsolidatedTarget.Key) {
        targetKeys.insert(key)
        productTypes[target.product.type.prettyName, default: .init()]
            .add(target: target, key: key)
    }

    /// Returns a unique name for the given `Target`.
    ///
    /// - Precondition: All targets have been added with `add(target:key:)`
    ///   before this is called.
    func uniqueName(
        for target: ConsolidatedTarget,
        key: ConsolidatedTarget.Key,
        baseName: String
    ) -> String {
        // If all changes are within the same consolidated target, we don't
        // need to show any distinguishers
        guard targetKeys.count > 1 else {
            return baseName
        }

        // TODO: Handle same name at different parts in the build graph?
        // This shouldn't happen for modules (though maybe with the new renaming
        // stuff in Swift it can?), but could for bundles.
        let distinguishers = productTypes[target.product.type.prettyName]!
            .distinguishers(
                target: target,
                key: key,
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
    /// For each operating system name among the `ConsolidatedTarget`s passed to
    /// `add(target:key:)`, there will be an entry in `oses`.
    /// `OperatingSystemComponents.add(target:consolidatedKey:)` will have been
    /// called for each `ConsolidatedTarget`.
    private var oses: [Platform.OS: OperatingSystemComponents] = [:]

    /// A count of `Target.distinguisherKey`s seen in `add(target:key:)`.
    ///
    /// If the count for a `distinguisherKey` is greater than one, then targets
    /// that have that key will have their configuration returned from
    /// `distinguisher()` instead of a string containing architecture, OS, etc.
    private var distinguisherKeys: [String: Set<ConsolidatedTarget.Key>] = [:]

    /// Adds another `Target` into consideration for `distinguishers()`.
    mutating func add(target: ConsolidatedTarget, key: ConsolidatedTarget.Key) {
        for target in target.targets.values {
            oses[target.platform.os, default: .init()]
                .add(target: target, consolidatedKey: key)
            distinguisherKeys[target.distinguisherKey, default: []].insert(key)
        }
    }

    /// Generates an array of user-facing strings that, along with a target
    /// name, uniquely distinguishes it from targets with the same non-
    /// distinguished name.
    ///
    /// - Precondition: All targets have been added with `add(target:key:)`
    ///   before this is called.
    ///
    /// - Parameters:
    ///   - target: The `ConsolidatedTarget` to generate a distinguisher for.
    ///   - key: The `ConsolidatedTarget.Key` for `target`.
    ///   - includeProductType: If `true`, the product type will be part of the
    ///     array returned.
    func distinguishers(
        target: ConsolidatedTarget,
        key: ConsolidatedTarget.Key,
        includeProductType: Bool
    ) -> [String] {
        var distinguishers: [String] = []
        var consolidatedDistinguishers: OrderedSet<String> = []
        var xcodeConfigurations: Set<String> = []
        let targets = target.sortedTargets

        if includeProductType {
            distinguishers.append(target.product.type.prettyName)
        }

        let includeOS = oses.count > 1

        guard !needsConfigurationDistinguishing(target: target) else {
            // The target name would be ambiguous, even with our distinguisher
            // components. We will show a shorted configuration hash instead,
            // which will be unique.
            if includeOS {
                consolidatedDistinguishers.append(
                    contentsOf: targets.map(\.platform.os.prettyName)
                )
                distinguishers.append(
                    consolidatedDistinguishers.joined(separator: ", ")
                )
            }

            distinguishers.append(prettyConfiguration(targets: targets))

            return distinguishers
        }

        for target in targets {
            let osDistinguisher = oses[target.platform.os]!.distinguisher(
                target: target,
                consolidatedKey: key,
                includeOS: includeOS
            )

            if !osDistinguisher.components.isEmpty {
                consolidatedDistinguishers.append(
                    osDistinguisher.components.joined(separator: " ")
                )
            }

            xcodeConfigurations.formUnion(osDistinguisher.xcodeConfigurations)
        }

        if !consolidatedDistinguishers.isEmpty {
            distinguishers.append(
                consolidatedDistinguishers.joined(separator: ", ")
            )
        }

        if !xcodeConfigurations.isEmpty {
            distinguishers.append(
                xcodeConfigurations.sorted().joined(separator: ", ")
            )
        }

        return distinguishers
    }

    private func needsConfigurationDistinguishing(
        target: ConsolidatedTarget
    ) -> Bool {
        return target.sortedTargets
            .contains { distinguisherKeys[$0.distinguisherKey]!.count > 1 }
    }

    /// Returns a user-facing string for the configurations of a given set of
    /// targets.
    private func prettyConfiguration(targets: [Target]) -> String {
        return Self.prettyConfigurations(targets.map(\.configuration))
    }

    /// Memoized configuration hashes.
    private static var configurationHashes: [[String]: String] = [:]

    static func prettyConfigurations(_ configurations: [String]) -> String {
        if let hash = configurationHashes[configurations] {
            return hash
        }

        let hash = String(configurations.sha1Hash().prefix(5))
        configurationHashes[configurations] = hash

        return hash
    }
}

/// `OperatingSystemComponents` collects properties of `Target`s for a given
/// operating system name and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct OperatingSystemComponents {
    struct Distinguisher {
        let components: [String]
        let xcodeConfigurations: Set<String>
    }

    /// Collects which minimum versions each `ConsolidatedTarget` contains.
    private var minimumVersionsByKeys: [
        ConsolidatedTarget.Key: Set<SemanticVersion>
    ] = [:]

    /// Maps operating system minimum versions to
    /// `VersionedOperatingSystemComponents`.
    ///
    /// For operating system minimum versions among the `Target`s passed to
    /// `add(target:consolidatedKey:)`, there will be an entry in
    /// `minimumVersions`.
    /// `VersionedOperatingSystemComponents.add(target:consolidatedKey:)` will
    /// have been called for each `Target`.
    private var minimumVersions: [
        SemanticVersion: VersionedOperatingSystemComponents
    ] = [:]

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target, consolidatedKey: ConsolidatedTarget.Key) {
        let minimumVersion = target.platform.minimumOsVersion

        minimumVersionsByKeys[consolidatedKey, default: []]
            .insert(minimumVersion)
        minimumVersions[minimumVersion, default: .init()]
            .add(target: target, consolidatedKey: consolidatedKey)
    }

    /// Potentially generates a user-facing string that, along with a target
    /// name, uniquely distinguishes it from targets with the same non-
    /// distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(target:consolidatedKey:)` before this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - consolidatedKey: The `ConsolidatedTarget.Key` of the
    ///     `ConsolidatedTarget` that `target` is a part of.
    ///   - includeOS: If `true`, the operating system name will be
    ///     part of the string returned.
    func distinguisher(
        target: Target,
        consolidatedKey: ConsolidatedTarget.Key,
        includeOS: Bool
    ) -> Distinguisher {
        var components: [String] = []
        let platform = target.platform
        let os = platform.os

        // We hide all but the OS name if the differences are within a
        // consolidated target
        let needsSubcomponents = minimumVersionsByKeys.count > 1

        let includeVersion = needsSubcomponents && minimumVersions.count > 1

        let versionDistinguisher: VersionedOperatingSystemComponents
            .Distinguisher?
        if needsSubcomponents {
            versionDistinguisher = minimumVersions[
                target.platform.minimumOsVersion
            ]!.distinguisher(
                target: target,
                includeVersion: includeVersion,
                forceIncludeEnvironment: minimumVersionsByKeys[consolidatedKey]!
                    .count > 1
            )
        } else {
            versionDistinguisher = nil
        }

        if let prefix = versionDistinguisher?.prefix {
            components.append(prefix)
        }

        if includeOS || includeVersion {
            components.append(os.prettyName)
        }

        if let suffix = versionDistinguisher?.suffix {
            components.append(contentsOf: suffix)
        }

        return Distinguisher(
            components: components,
            xcodeConfigurations: versionDistinguisher?.xcodeConfigurations ?? []
        )
    }
}

/// `VersionedOperatingSystemComponents` collects properties of `Target`s for a
/// given operating system version and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct VersionedOperatingSystemComponents {
    struct Distinguisher {
        let prefix: String?
        let suffix: [String]
        let xcodeConfigurations: Set<String>
    }

    /// The set of `ConsolidatedTarget.Key`s among the targets passed to
    /// `add(target:consolidatedKey:)`.
    private var consolidatedKeys: Set<ConsolidatedTarget.Key> = []

    /// Maps platform environments (e.g. "Simulator") to
    /// `EnvironmentSystemComponents`.
    ///
    /// For operating system minimum versions among the `Target`s passed to
    /// `add(target:consolidatedKey:)`, there will be an entry in
    /// `environments`.
    /// `EnvironmentSystemComponents.add(target:consolidatedKey:)` will have
    /// been called for each `Target`.
    private var environments: [String: EnvironmentSystemComponents] = [:]

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target, consolidatedKey: ConsolidatedTarget.Key) {
        consolidatedKeys.insert(consolidatedKey)
        environments[target.platform.variant.environment, default: .init()]
            .add(target: target, consolidatedKey: consolidatedKey)
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(target:consolidatedKey:)` before this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - includeVersion: If `true`, the operating system version will be
    ///     part of the `Distinguisher` returned.
    ///   - forceIncludeEnvironment: If `true`, the platform environment will be
    ///     part of the `Distinguisher` returned.
    func distinguisher(
        target: Target,
        includeVersion: Bool,
        forceIncludeEnvironment: Bool
    ) -> Distinguisher {
        let platform = target.platform

        // We hide all but the OS version if the differences are within a
        // consolidated target
        let needsSubcomponents = forceIncludeEnvironment ||
            consolidatedKeys.count > 1

        let environmentDistinguisher: EnvironmentSystemComponents.Distinguisher?
        if needsSubcomponents {
            environmentDistinguisher = environments[
                platform.variant.environment
            ]!.distinguisher(
                target: target,
                includeEnvironment: forceIncludeEnvironment ||
                    environments.count > 1
            )
        } else {
            environmentDistinguisher = nil
        }

        let prefix = environmentDistinguisher?.prefix

        var suffix: [String] = []

        if includeVersion {
            suffix.append(platform.minimumOsVersion.pretty)
        }
        if let environmentSuffix = environmentDistinguisher?.suffix {
            suffix.append(environmentSuffix)
        }

        return Distinguisher(
            prefix: prefix,
            suffix: suffix,
            xcodeConfigurations: environmentDistinguisher?
                .xcodeConfigurations ?? []
        )
    }
}

/// `EnvironmentSystemComponents` collects properties of `Target`s for a
/// given platform environment and provides the capability to generate a
/// distinguisher string for any of the `Target`s it collected properties from.
struct EnvironmentSystemComponents {
    struct Distinguisher {
        let prefix: String?
        let suffix: String?
        let xcodeConfigurations: Set<String>
    }

    /// The set of `ConsolidatedTarget.Key`s among the targets passed to
    /// `add(target:consolidatedKey:)`.
    private var consolidatedKeys: Set<ConsolidatedTarget.Key> = []

    /// For architectures among the `Target`s passed to
    /// `add(target:consolidatedKey:)`, there will be an entry in
    /// `archs`.
    /// `ArchitectureComponents.add(target:consolidatedKey:)` will have
    /// been called for each `Target`.
    private var archs: [String: ArchitectureComponents] = [:]

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target, consolidatedKey: ConsolidatedTarget.Key) {
        consolidatedKeys.insert(consolidatedKey)
        archs[target.platform.arch, default: .init()]
            .add(target: target, consolidatedKey: consolidatedKey)
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(target:consolidatedKey:)` before this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - includeEnvironment: If `true`, the platform environment will be part
    ///     of the `Distinguisher` returned.
    func distinguisher(
        target: Target,
        includeEnvironment: Bool
    ) -> Distinguisher {
        let platform = target.platform

        // We hide all but the platform environment if the differences are
        // within a consolidated target
        let needsSubcomponents = consolidatedKeys.count > 1

        let archDistinguisher: ArchitectureComponents.Distinguisher?
        if needsSubcomponents {
            archDistinguisher = archs[platform.arch]!.distinguisher(
                target: target,
                includeArch: archs.count > 1
            )
        } else {
            archDistinguisher = nil
        }

        let suffix = includeEnvironment ? platform.variant.environment : nil

        return Distinguisher(
            prefix: archDistinguisher?.arch,
            suffix: suffix,
            xcodeConfigurations: archDistinguisher?.xcodeConfigurations ?? []
        )
    }
}

/// `ArchitectureComponents` collects properties of `Target`s for a
/// given architecture and provides the capability to generate a distinguisher
/// string for any of the `Target`s it collected properties from.
struct ArchitectureComponents {
    struct Distinguisher {
        let arch: String?
        let xcodeConfigurations: Set<String>
    }

    /// The set of `ConsolidatedTarget.Key`s among the targets passed to
    /// `add(target:consolidatedKey:)`.
    private var consolidatedKeys: Set<ConsolidatedTarget.Key> = []

    /// The set of xcodeConfigurations among the targets passed to
    /// `add(target:consolidatedKey:)`.
    private var xcodeConfigurations: Set<String> = []

    /// Adds another `Target` into consideration for `distinguisher()`.
    mutating func add(target: Target, consolidatedKey: ConsolidatedTarget.Key) {
        consolidatedKeys.insert(consolidatedKey)
        xcodeConfigurations.formUnion(target.xcodeConfigurations)
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(target:consolidatedKey:)` before this is called.
    ///
    /// - Parameters:
    ///   - target: The `Target` to generate a distinguisher for.
    ///   - includeArch: If `true`, the archiecture will be part of the
    ///     `Distinguisher` returned.
    func distinguisher(
        target: Target,
        includeArch: Bool
    ) -> Distinguisher {
        let platform = target.platform

        // We hide all but the Xcode configuration if the differences are
        // within a consolidated target
        let needsSubcomponents = consolidatedKeys.count > 1

        let xcodeConfigurations = needsSubcomponents &&
            xcodeConfigurations.count > 1 ? target.xcodeConfigurations : []
        let arch = includeArch ? platform.arch : nil

        return Distinguisher(
            arch: arch,
            xcodeConfigurations: xcodeConfigurations
        )
    }
}

extension ConsolidatedTarget {
    /// The normalized name is used during target disambiguation. It allows the
    /// logic to differentiate targets where the names only differ by case.
    var normalizedName: String {
        return name.lowercased()
    }

    /// The normalized label is used during target disambiguation. It allows the
    /// logic to differentiate targets where the names only differ by case.
    var normalizedLabel: String {
        return "\(label)".lowercased()
    }
}

private extension Target {
    /// A key that corresponds to the most-distinguished string that
    /// `ProductTypeComponents.distinguisher()` can return for this
    /// `Target`.
    var distinguisherKey: String {
        return ([
            platform.arch,
            platform.os.rawValue,
            platform.minimumOsVersion.pretty,
            platform.variant.environment,
        ] + xcodeConfigurations).joined(separator: "-")
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

private extension Sequence where Element == String {
    /// Computes a sha1 hash string for this `Sequence<String>`.
    func sha1Hash() -> String {
        var hasher = Insecure.SHA1()

        for string in sorted() {
            hasher.update(data: string.data(using: .utf8)!)
        }

        return hasher.finalize()
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
