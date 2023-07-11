import CryptoKit
import GeneratorCommon
import OrderedCollections
import PBXProj

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

extension Generator {
    struct DisambiguateTargets {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        func callAsFunction(
            _ consolidatedTargets: [ConsolidatedTarget]
        )-> [DisambiguatedTarget] {
            return callable(consolidatedTargets)
        }
    }
}

// MARK: - DisambiguateTargets.Callable

extension Generator.DisambiguateTargets {
    public typealias Callable = (
        _ consolidatedTargets: [ConsolidatedTarget]
    ) -> [DisambiguatedTarget]

    static func defaultCallable(
        _ consolidatedTargets: [ConsolidatedTarget]
    ) -> [DisambiguatedTarget] {
        // Gather all information needed to distinguish the targets
        var labelsByName: [String: Set<String>] = [:]
        var names: [String: TargetComponents] = [:]
        var labels: [String: TargetComponents] = [:]
        for consolidatedTarget in consolidatedTargets {
            let normalizedName = consolidatedTarget.normalizedName
            let normalizedLabel = consolidatedTarget.normalizedLabel
            labelsByName[normalizedName, default: []].insert(normalizedLabel)
            names[normalizedName, default: .init()]
                .add(target: consolidatedTarget)
            labels[normalizedLabel, default: .init()]
                .add(target: consolidatedTarget)
        }

        // And then distinguish them
        var disambiguatedTargets: [DisambiguatedTarget] = []
        for consolidatedTarget in consolidatedTargets {
            let name: String
            let componentKey: String
            let components: [String: TargetComponents]
            let normalizedName = consolidatedTarget.normalizedName
            if labelsByName[normalizedName]!.count == 1 {
                name = consolidatedTarget.name
                componentKey = normalizedName
                components = names
            } else {
                name = "\(consolidatedTarget.label)"
                componentKey = consolidatedTarget.normalizedLabel
                components = labels
            }

            disambiguatedTargets.append(
                .init(
                    name: components[componentKey]!.uniqueName(
                        for: consolidatedTarget,
                        baseName: name
                    ),
                    target: consolidatedTarget
                )
            )
        }

        return disambiguatedTargets.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

struct TargetComponents {
    /// The set of `ConsolidatedTarget.Key`s among the targets passed to
    /// `add(target:key:)`.
    private var targetKeys: Set<ConsolidatedTarget.Key> = []

    /// Maps target product type names to `ProductTypeComponents`.
    ///
    /// For each product type name among the `ConsolidatedTarget`s passed to
    /// `add(target:)`, there will be an entry in `productTypes`.
    /// `ProductTypeComponents.add(target)` will have been called for each
    /// `ConsolidatedTarget`.
    private var productTypes: [String: ProductTypeComponents] = [:]

    /// Adds another `Target` into consideration for `uniqueName()`.
    mutating func add(target consolidatedTarget: ConsolidatedTarget) {
        targetKeys.insert(consolidatedTarget.key)
        productTypes[
            consolidatedTarget.productType.prettyName, default: .init()
        ].add(target: consolidatedTarget)
    }

    /// Returns a unique name for the given `Target`.
    ///
    /// - Precondition: All targets have been added with `add(target:key:)`
    ///   before this is called.
    func uniqueName(
        for consolidatedTarget: ConsolidatedTarget,
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
        let distinguishers =
            productTypes[consolidatedTarget.productType.prettyName]!
            .distinguishers(
                target: consolidatedTarget,
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
    mutating func add(target consolidatedTarget: ConsolidatedTarget) {
        let key = consolidatedTarget.key
        for target in consolidatedTarget.sortedTargets {
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
        target consolidatedTarget: ConsolidatedTarget,
        includeProductType: Bool
    ) -> [String] {
        var distinguishers: [String] = []
        var consolidatedDistinguishers: OrderedSet<String> = []
        var xcodeConfigurations: Set<String> = []
        let targets = consolidatedTarget.sortedTargets

        if includeProductType {
            distinguishers.append(consolidatedTarget.productType.prettyName)
        }

        let includeOS = oses.count > 1

        guard !needsConfigurationDistinguishing(target: consolidatedTarget)
        else {
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
                consolidatedKey: consolidatedTarget.key,
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
        target consolidatedTarget: ConsolidatedTarget
    ) -> Bool {
        return consolidatedTarget.sortedTargets
            .contains { distinguisherKeys[$0.distinguisherKey]!.count > 1 }
    }

    /// Returns a user-facing string for the configurations of a given set of
    /// targets.
    private func prettyConfiguration(targets: [Target]) -> String {
        return Self.prettyConfigurations(
            targets.map {
                // TODO: Stop relying on the fact that configuration is part of TargetID
                String($0.id.rawValue.split(separator: " ", maxSplits: 1).last!)
            }
        )
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
        let xcodeConfigurations: [String]
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
        let minimumVersion = target.osVersion

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
                target.osVersion
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
        let xcodeConfigurations: [String]
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
        environments[target.platform.environment, default: .init()]
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
        // We hide all but the OS version if the differences are within a
        // consolidated target
        let needsSubcomponents = forceIncludeEnvironment ||
            consolidatedKeys.count > 1

        let environmentDistinguisher: EnvironmentSystemComponents.Distinguisher?
        if needsSubcomponents {
            environmentDistinguisher = environments[
                target.platform.environment
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
            suffix.append(target.osVersion.pretty)
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
        let xcodeConfigurations: [String]
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
        archs[target.arch, default: .init()]
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
        // We hide all but the platform environment if the differences are
        // within a consolidated target
        let needsSubcomponents = consolidatedKeys.count > 1

        let archDistinguisher: ArchitectureComponents.Distinguisher?
        if needsSubcomponents {
            archDistinguisher = archs[target.arch]!.distinguisher(
                target: target,
                includeArch: archs.count > 1
            )
        } else {
            archDistinguisher = nil
        }

        let suffix = includeEnvironment ? target.platform.environment : nil

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
        let xcodeConfigurations: [String]
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
        // We hide all but the Xcode configuration if the differences are
        // within a consolidated target
        let needsSubcomponents = consolidatedKeys.count > 1

        let xcodeConfigurations = needsSubcomponents &&
            xcodeConfigurations.count > 1 ? target.xcodeConfigurations : []
        let arch = includeArch ? target.arch : nil

        return Distinguisher(
            arch: arch,
            xcodeConfigurations: xcodeConfigurations
        )
    }
}

extension ConsolidatedTarget {
    var name: String {
        return label.name
    }

    /// The normalized label is used during target disambiguation. It allows the
    /// logic to differentiate targets where the names only differ by case.
    var normalizedLabel: String {
        return "\(label)".lowercased()
    }

    /// The normalized name is used during target disambiguation. It allows the
    /// logic to differentiate targets where the names only differ by case.
    var normalizedName: String {
        return name.lowercased()
    }
}

private extension Target {
    /// A key that corresponds to the most-distinguished string that
    /// `ProductTypeComponents.distinguisher()` can return for this
    /// `Target`.
    var distinguisherKey: String {
        return ([
            arch,
            "\(platform.os)",
            osVersion.pretty,
            platform.environment,
        ] + xcodeConfigurations).joined(separator: "-")
    }
}

private extension PBXProductType {
    var prettyName: String {
        switch self {
        case .application: return "App"
        case .messagesApplication: return "Messages App"
        case .onDemandInstallCapableApplication: return "App Clip"
        case .watchApp: return "watchOS 1.0 App"
        case .watch2App: return "App"
        case .watch2AppContainer: return "App Container"

        case .appExtension: return "App Extension"
        case .intentsServiceExtension: return "Intents Service Extension"
        case .messagesExtension: return "Messages Extension"
        case .stickerPack: return "Sticker Pack"
        case .tvExtension: return "App Extension"

        case .extensionKitExtension: return "ExtensionKit Extension"
        case .watchExtension: return "WatchKit 1.0 Extension"
        case .watch2Extension: return "WatchKit Extension"
        case .xcodeExtension: return "Xcode Extension"

        case .bundle: return "Bundle"
        case .ocUnitTestBundle: return "OC Unit Tests"
        case .unitTestBundle: return "Unit Tests"
        case .uiTestBundle: return "UI Tests"

        case .framework: return "Framework"
        case .staticFramework: return "Static Framework"
        case .xcFramework: return "XCFramework"

        case .dynamicLibrary: return "Dylib"
        case .staticLibrary: return "Library"

        case .driverExtension: return "Driver Extension"
        case .instrumentsPackage: return "Instruments Package"
        case .metalLibrary: return "Metal Library"
        case .systemExtension: return "System Extension"
        case .commandLineTool: return "Command Line Tool"
        case .xpcService: return "XPC Service"
        }
    }
}

private extension Platform {
    private static let deviceEnvironment = "Device"
    private static let simulatorEnvironment = "Simulator"

    var environment: String {
        switch self {
        case .macOS: return Self.deviceEnvironment
        case .iOSDevice: return Self.deviceEnvironment
        case .iOSSimulator: return Self.simulatorEnvironment
        case .tvOSDevice: return Self.deviceEnvironment
        case .tvOSSimulator: return Self.simulatorEnvironment
        case .watchOSDevice: return Self.deviceEnvironment
        case .watchOSSimulator: return Self.simulatorEnvironment
        }
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
