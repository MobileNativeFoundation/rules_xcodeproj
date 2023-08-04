import CryptoKit
import GeneratorCommon
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
        var labelsByModuleNameAndProductType:
            [ModuleNameAndProductType: Set<String>] = [:]
        var labelsByNameAndProductType:
            [NameAndProductType: Set<String>] = [:]
        var names: [String: TargetComponents] = [:]
        var labels: [String: TargetComponents] = [:]
        for target in targets.values {
            let normalizedLabel = target.normalizedLabel
            labelsByModuleNameAndProductType[.init(target: target), default: []]
                .insert(normalizedLabel)
            labelsByNameAndProductType[.init(target: target), default: []]
                .insert(normalizedLabel)
        }
        for (key, target) in targets {
            let moduleNameAndProductType =
                ModuleNameAndProductType(target: target)
            guard labelsByModuleNameAndProductType[moduleNameAndProductType]!
                .count != 1
            else {
                names[
                    moduleNameAndProductType.normalizedModuleName,
                    default: .init()
                ].add(target: target, key: key)
                continue
            }

            let nameAndProductType = NameAndProductType(target: target)
            guard labelsByNameAndProductType[nameAndProductType]!.count != 1
            else {
                names[nameAndProductType.normalizedName, default: .init()]
                    .add(target: target, key: key)
                continue
            }

            labels[target.normalizedLabel, default: .init()]
                .add(target: target, key: key)
        }

        // And then distinguish them
        var uniqueValues = [
            ConsolidatedTarget.Key: DisambiguatedTarget,
        ](minimumCapacity: targets.count)
        for (key, target) in targets {
            let moduleNameAndProductType =
                ModuleNameAndProductType(target: target)
            guard labelsByModuleNameAndProductType[moduleNameAndProductType]!
                .count != 1
            else {
                uniqueValues[key] = DisambiguatedTarget(
                    name: names[moduleNameAndProductType.normalizedModuleName]!
                        .uniqueName(
                            for: target,
                            key: key,
                            baseName: target.moduleName
                        ),
                    target: target
                )
                continue
            }

            let nameAndProductType = NameAndProductType(target: target)
            guard
                labelsByNameAndProductType[nameAndProductType]!.count != 1
            else {
                uniqueValues[key] = DisambiguatedTarget(
                    name: names[nameAndProductType.normalizedName]!.uniqueName(
                        for: target,
                        key: key,
                        baseName: target.name
                    ),
                    target: target
                )
                continue
            }

            uniqueValues[key] = DisambiguatedTarget(
                name: labels[target.normalizedLabel]!.uniqueName(
                    for: target,
                    key: key,
                    baseName: target.label.description
                ),
                target: target
            )
        }

        return DisambiguatedTargets(
            keys: consolidatedTargets.keys,
            targets: uniqueValues
        )
    }
}

private struct ModuleNameAndProductType: Equatable, Hashable {
    let normalizedModuleName: String
    let productType: PBXProductType

    init(target: ConsolidatedTarget) {
        self.normalizedModuleName = target.normalizedModuleName
        self.productType = target.product.type
    }
}

private struct NameAndProductType: Equatable, Hashable {
    let normalizedName: String
    let productType: PBXProductType

    init(target: ConsolidatedTarget) {
        self.normalizedName = target.normalizedName
        self.productType = target.product.type
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
        productTypes[target.product.type.prettyName, default: .init()].add(
            target: target,
            consolidatedKey: key
        )
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
    /// Collects the unique set of operating system names among
    /// `ConsolidatedTarget`s passed to `add(target:consolidatedKey:)`.
    private var consolidatedOSes: Set<Set<Platform.OS>> = []

    /// Collects the unique set of Xcode configuration names among
    /// `ConsolidatedTarget`s passed to `add(target:consolidatedKey:)`.
    private var consolidatedXcodeConfigurations: Set<Set<String>> = []

    /// Maps operating system names to `OperatingSystemComponents`.
    ///
    /// For each operating system name among the `ConsolidatedTarget`s passed to
    /// `add(target:key:)`, there will be an entry in `oses`.
    /// `OperatingSystemComponents.add(target:consolidatedKey:)` will have been
    /// called for each `ConsolidatedTarget`.
    private var oses: [Platform.OS: OperatingSystemComponents] = [:]

    /// A count of `ConsolidatedTarget.DistinguisherKey`s seen in
    /// `add(target:key:)`.
    ///
    /// If the count for a `DistinguisherKey` is greater than one, then targets
    /// that have that key will have their configuration returned from
    /// `distinguisher()` instead of a string containing architecture, OS, etc.
    private var consolidatedDistinguisherKeys:
        [ConsolidatedTarget.DistinguisherKey: Set<ConsolidatedTarget.Key>] = [:]

    /// A count of `Target.DistinguisherKey`s seen in `add(target:key:)`.
    ///
    /// If the count for a `DistinguisherKey` is greater than one, then targets
    /// that have that key will have their configuration returned from
    /// `distinguisher()` instead of a string containing architecture, OS, etc.
    private var targetDistinguisherKeys:
        [Target.DistinguisherKey: Set<ConsolidatedTarget.Key>] = [:]

    /// Adds another `ConsolidatedTarget.DistinguisherKey` into consideration
    /// for `distinguishers()`.
    mutating func add(
        target: ConsolidatedTarget,
        consolidatedKey: ConsolidatedTarget.Key
    ) {
        let distinguisherKey = target.distinguisherKey

        consolidatedDistinguisherKeys[distinguisherKey, default: []]
            .insert(consolidatedKey)
        target.targetDistinguisherKeys.forEach { distinguisherKey in
            targetDistinguisherKeys[distinguisherKey, default: []]
                .insert(consolidatedKey)
        }

        consolidatedXcodeConfigurations
            .insert(distinguisherKey.xcodeConfigurations)

        let oses = distinguisherKey.components

        consolidatedOSes.insert(Set(oses.keys))

        for (os, osVersions) in oses {
            self.oses[os, default: .init()]
                .add(osVersions: osVersions, consolidatedKey: consolidatedKey)
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
        let targets = target.sortedTargets

        if includeProductType {
            distinguishers.append(target.product.type.prettyName)
        }

        let includeOS = consolidatedOSes.count > 1

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
        }

        if !consolidatedDistinguishers.isEmpty {
            distinguishers.append(
                consolidatedDistinguishers.sorted().joined(separator: ", ")
            )
        }

        if consolidatedXcodeConfigurations.count > 1 {
            distinguishers.append(
                target.distinguisherKey.xcodeConfigurations
                    .sorted().joined(separator: ", ")
            )
        }

        if needsConfigurationDistinguishing(target: target) {
            // The target name would be ambiguous, even with our distinguisher
            // components. We will show a shorted configuration hash as well,
            // which will be unique.
            distinguishers.append(prettyConfiguration(targets: targets))
        }

        return distinguishers
    }

    private func needsConfigurationDistinguishing(
        target: ConsolidatedTarget
    ) -> Bool {
        return
            consolidatedDistinguisherKeys[target.distinguisherKey]!.count > 1 ||
            target.targetDistinguisherKeys.contains { distinguisherKey in
                targetDistinguisherKeys[distinguisherKey]!.count > 1
            }
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
    }

    /// Collects which minimum versions each `ConsolidatedTarget` contains.
    private var minimumVersionsByKeys: [
        ConsolidatedTarget.Key: Set<SemanticVersion>
    ] = [:]

    /// Collects the unique set of minimum versions among `ConsolidatedTarget`s
    /// passed to `add(osVersions:consolidatedKey:)`.
    private var consolidatedMinimumVersions: Set<Set<SemanticVersion>> = []

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

    /// Adds another `ConsolidatedTarget.DistinguisherKey` into consideration
    /// for `distinguisher()`.
    mutating func add(
        osVersions: ConsolidatedTarget.DistinguisherKey.OSVersions,
        consolidatedKey: ConsolidatedTarget.Key
    ) {
        let minimumVersions = Set(osVersions.keys)
        minimumVersionsByKeys[consolidatedKey] = minimumVersions
        consolidatedMinimumVersions.insert(minimumVersions)

        for (minimumVersion, environments) in osVersions {
            self.minimumVersions[minimumVersion, default: .init()].add(
                environments: environments,
                consolidatedKey: consolidatedKey
            )
        }
    }

    /// Potentially generates a user-facing string that, along with a target
    /// name, uniquely distinguishes it from targets with the same non-
    /// distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(osVersions:consolidatedKey:)` before this is called.
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

        let needsSubcomponents = minimumVersionsByKeys.count > 1

        let includeVersion = needsSubcomponents &&
            consolidatedMinimumVersions.count > 1

        let versionDistinguisher: VersionedOperatingSystemComponents
            .Distinguisher?
        if needsSubcomponents {
            versionDistinguisher = minimumVersions[
                target.platform.minimumOsVersion
            ]!.distinguisher(
                target: target,
                includeVersion: includeVersion,
                forceIncludeEnvironment:
                    minimumVersionsByKeys[consolidatedKey]!.count > 1
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
            components: components
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
    }

    /// The set of `ConsolidatedTarget.Key`s among the targets passed to
    /// `add(environments:consolidatedKey:)`.
    private var consolidatedKeys: Set<ConsolidatedTarget.Key> = []

    /// Collects the unique set of platform environments among
    /// `ConsolidatedTarget`s passed to `add(environments:consolidatedKey:)`.
    private var consolidatedEnvironments: Set<Set<String>> = []

    /// Maps platform environments (e.g. "Simulator") to
    /// `EnvironmentSystemComponents`.
    ///
    /// For operating system minimum versions among the `Target`s passed to
    /// `add(environments:consolidatedKey:)`, there will be an entry in
    /// `environments`.
    /// `EnvironmentSystemComponents.add(target:consolidatedKey:)` will have
    /// been called for each `Target`.
    private var environments: [String: EnvironmentSystemComponents] = [:]

    /// Adds another `ConsolidatedTarget.DistinguisherKey` into consideration
    /// for `distinguisher()`.
    mutating func add(
        environments: ConsolidatedTarget.DistinguisherKey.Environments,
        consolidatedKey: ConsolidatedTarget.Key
    ) {
        consolidatedKeys.insert(consolidatedKey)
        consolidatedEnvironments.insert(Set(environments.keys))

        for (environment, archs) in environments {
            self.environments[environment, default: .init()]
                .add(archs: archs, consolidatedKey: consolidatedKey)
        }
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(environments:consolidatedKey:)` before this is called.
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

        let needsSubcomponents = forceIncludeEnvironment ||
            consolidatedKeys.count > 1

        let environmentDistinguisher: EnvironmentSystemComponents.Distinguisher?
        if needsSubcomponents {
            environmentDistinguisher = environments[
                platform.variant.environment
            ]!.distinguisher(
                target: target,
                includeEnvironment: forceIncludeEnvironment ||
                    consolidatedEnvironments.count > 1
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
            suffix: suffix
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
    }

    /// Collects the unique set of architectures among `ConsolidatedTarget`s
    /// passed to `add(archs:consolidatedKey:)`.
    private var consolidatedArchs: Set<Set<String>> = []

    /// Adds another `ConsolidatedTarget.DistinguisherKey` into consideration
    /// for `distinguisher()`.
    mutating func add(
        archs: ConsolidatedTarget.DistinguisherKey.Archs,
        consolidatedKey: ConsolidatedTarget.Key
    ) {
        consolidatedArchs.insert(archs)
    }

    /// Potentially generates user-facing strings that, along with a target
    /// name and previous component distinguishers, uniquely distinguishes it
    /// from targets with the same non-distinguished name.
    ///
    /// - Precondition: All targets have been added with
    ///   `add(archs:consolidatedKey:)` before this is called.
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

        return Distinguisher(
            prefix: consolidatedArchs.count > 1 ? platform.arch : nil,
            suffix: includeEnvironment ? platform.variant.environment : nil
        )
    }
}

extension ConsolidatedTarget {
    /// The normalized module name is used during target disambiguation. It
    /// allows the logic to differentiate targets where the module names only
    /// differ by case.
    var normalizedModuleName: String {
        return moduleName.lowercased()
    }

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
