import PathKit
import ToolCommon
import XcodeProj

func xcodeTargetsToBazelPackages(
    _ xcodeTargets: [PBXNativeTarget],
    localSwiftPackages: [String: String]
) throws -> [Package] {
    var bazelDepsByXcodeTarget: [PBXNativeTarget: [MetaTarget]] = [:]
    var allIntentDefinitions: Set<String> = []
    for (xcodeTarget, bazelDeps) in try xcodeTargets.map({ ($0, try xcodeTargetToBazelTargetDeps($0)) }) {
        bazelDepsByXcodeTarget[xcodeTarget] = bazelDeps
        allIntentDefinitions.formUnion(bazelDeps.flatMap { $0.intentDefinitions })
    }

    let packagePaths = Set(
        bazelDepsByXcodeTarget.values.flatMap {
            $0.map { $0.target.label.package }
        }
    ).sorted().reversed()

    let intentTargets = Dictionary(uniqueKeysWithValues: try allIntentDefinitions.map { path in
        guard
            let package = packagePaths.first(where: { path.hasPrefix($0) })
        else {
            throw PreconditionError(
                message: #"Package for "\#(path)" not found"#
            )
        }

        let relativePath = path.dropFirst(package.count + 1)
        let name = "\(relativePath.split(separator: "/").last!.split(separator: ".").first!).intent"

        return (
            path: path,
            target: MetaTarget(
                target: .init(
                    kind: .appleIntentLibrary,
                    label: Label(
                        package: package,
                        name: name
                    ),
                    singleAttrs: [
                        "language": "Swift",
                        "src": .string(String(relativePath)),
                    ],
                    listAttrs: [
                        // FIXME: Give better visibility? Need to allow other targets to include as a source file
                        "visibility": ["//visibility:public"],
                    ]
                )
            )
        )
    })

    // Normal dependencies
    var packages: [String: Package] = [:]
    var topLevelTargets: [Label] = []
    for (xcodeTarget, bazelDeps) in bazelDepsByXcodeTarget {
        let deps = xcodeTarget.dependencies
            .compactMap { $0.target as? PBXNativeTarget }
            .flatMap { bazelDepsByXcodeTarget[$0] ?? [] }
            .filter { $0.canBeTransitiveDep }
            .map { $0.target }
            .sorted { $0.label.description < $1.label.description }

        var swiftPkgDeps: [Attr] = []
        var swiftPkgs: [String] = []
        var localSwiftPkgs: [String] = []
        for dep in xcodeTarget.packageProductDependencies {
            let product = dep.productName

            let repository: String
            // FIXME: both package and name are Optional?
            if let package = dep.package?.name {
                repository = swiftpkgRepo(package)
                swiftPkgs.append(repository)
            } else {
                guard let localSwiftPackage = localSwiftPackages[product] else {
                    throw PreconditionError(message: "Local Swift package for \(product) not found")
                }
                // FIXME: Do this right
                repository = swiftpkgRepo(localSwiftPackage)
                swiftPkgs.append(repository)
//                repository = localSwiftpkgRepo(localSwiftPackage)
//                localSwiftPkgs.append(repository)
            }

            swiftPkgDeps.append(
                .string(
                    Label(
                        repository: "@" + repository,
                        package: "",
                        name: product
                    ).description
                )
            )
        }

        for bazelDep in bazelDeps {
            var target = bazelDep.target

            if target.kind.isTopLevelTarget {
                topLevelTargets.append(target.label)
            }

            target.setDeps(deps)

            if target.kind == .swiftLibrary {
                // FIXME: Add `rules_swift_package_manager` to `MODULE.bazel`
                // somehow
                target.listAttrs["deps", default: []]
                    .append(contentsOf: swiftPkgDeps)
            }

            let intentDefinitionsSrcs = bazelDep.intentDefinitions.map { path in
                // We return a raw string here instead of label because
                // buildozer won't shorten the label for us (because of the
                // `glob`)
                let label = intentTargets[path]!.target.label
                if label.package == target.label.package {
                    return ":\(label.name)"
                } else {
                    return label.description
                }
            }
            if !intentDefinitionsSrcs.isEmpty {
                target.singleAttrs["srcs", default: .raw("")]
                    .append(
                        "+ [\(intentDefinitionsSrcs.map { $0.quoted }.joined(separator: ", "))]"
                    )
            }

            packages[
                target.label.package,
                default: .init(path: Path(target.label.package))
            ].addTarget(
                target,
                requiredSymbols: bazelDep.requiredSymbols,
                swiftPkgs: swiftPkgs,
                localSwiftPkgs: localSwiftPkgs
            )
        }
    }

    for dep in intentTargets.values {
        packages[
            dep.target.label.package,
            default: .init(path: Path(dep.target.label.package))
        ].addTarget(dep.target, requiredSymbols: dep.requiredSymbols)
    }

    packages[""] = Package(
        path: "",
        // FIXME: Use `RuleKind` extension
        loadStatements: [
            "@rules_xcodeproj//xcodeproj:defs.bzl": ["xcodeproj", "top_level_target"],
        ],
        targets: [
            .init(
                kind: .xcodeproj,
                label: .init(package: "", name: "xcodeproj"),
                singleAttrs: [
                    "generation_mode": "incremental",
                    "top_level_targets": .raw(#"""
[\#(
    topLevelTargets.sorted { $0.description < $1.description }.map { label in
        // FIXME: Calculate `target_environments`
        return (#"""
top_level_target("\#(label.description)", target_environments = ["simulator"])
"""#)
    }.joined(separator: ",")
)]
"""#)
                ]
            )
        ]
    )

    return Array(packages.values.sorted { $0.path < $1.path })
}

private func xcodeTargetToBazelTargetDeps(
    _ xcodeTarget: PBXNativeTarget
) throws -> [MetaTarget] {
    guard let productType = xcodeTarget.productType else {
        return []
    }

    let package = try xcodeTarget.findPackage()
    let baseName = xcodeTarget.name.normalizedForLabel

    let intentDefinitions = try xcodeTarget.sourceFiles()
        .compactMap { try $0.fullPath(sourceRoot: "")?.string }
        .filter { $0.hasSuffix(".intentdefinition") }

    var targets: [MetaTarget]
    if productType == .application {
        let libraryLabel =
            Label(package: package, name: "\(baseName).library")

        targets = [
            MetaTarget(
                target: .init(
                    // FIXME: Do the correct thing based on platform
                    kind: .iOSApplication,
                    label: .init(package: package, name: baseName),
                    singleAttrs: [
                        // FIXME: Calculate this from `PRODUCT_BUNDLE_IDENTIFIER`
                        "bundle_id": "org.joinmastodon.app",
                        // FIXME: Calculate this from `CODE_SIGN_ENTITLEMENTS`
                        "entitlements": .string("\(baseName).entitlements"),
                        // FIXME: Calculate this from `{PLATFORM}_DEPLOYMENT_TARGET`
                        "minimum_os_version": "16.0",
                        // FIXME: Detect this properly from `resourcesBuildPhase()`. Issue currently is that `fullPath` only gives a single version for variant groups, and it fails when a `Base` doesn't exist. Need it to return multiple files instead.
                        "resources": .raw(#"glob(["Resources/**", "Supporting Files/**"], exclude = [".*", "Resources/Preview Assets.xcassets"])"#),
                    ],
                    listAttrs: [
                        // FIXME: Calculate this from `TARGETED_DEVICE_FAMILY`
                        "families": ["iphone","ipad"],
                        // FIXME: Calculate this from `INFOPLIST_FILE`, or create one from `INFOPLIST_KEY_*` settings
                        "infoplists": ["Info.plist"],
                        // FIXME: Give better visibility? Need to allow xcodeproj and tests. Can probably calculate the tests one?
                        "visibility": ["//visibility:public"],
                        "deps": [.string(libraryLabel.description)],
                    ]
                )
            ),
            MetaTarget(
                target: .init(
                    // FIXME: Support multiple languages, including mixed-language
                    kind: .swiftLibrary,
                    label: libraryLabel,
                    singleAttrs: [
                        "module_name": .string(baseName),
                        "srcs": .raw(#"glob(["**/*.swift"])"#),
                    ]
                ),
                intentDefinitions: intentDefinitions,
                canBeTransitiveDep: false
            ),
        ]
    } else if productType == .appExtension {
        let libraryLabel =
            Label(package: package, name: "\(baseName).library")

        targets = [
            MetaTarget(
                target: .init(
                    // FIXME: Do the correct thing based on platform
                    kind: .iOSExtension,
                    label: .init(package: package, name: baseName),
                    singleAttrs: [
                        // FIXME: Calculate this from `PRODUCT_BUNDLE_IDENTIFIER`
                        "bundle_id": .string("org.joinmastodon.app.\(xcodeTarget.name)"),
                        // FIXME: Calculate this from `CODE_SIGN_ENTITLEMENTS`
                        "entitlements": .string("\(baseName).entitlements"),
                        // FIXME: Calculate this from `{PLATFORM}_DEPLOYMENT_TARGET`
                        "minimum_os_version": "16.0",
                        // FIXME: Detect this properly from `resourcesBuildPhase()`. Issue currently is that `fullPath` only gives a single version for variant groups, and it fails when a `Base` doesn't exist. Need it to return multiple files instead.
                        "resources": .raw(#"glob(["**/*.lproj/**", "**/*.js", "**/*.xcassets/**"], exclude = [".*"])"#),
                    ],
                    listAttrs: [
                        // FIXME: Calculate this from `TARGETED_DEVICE_FAMILY`
                        "families": ["iphone","ipad"],
                        // FIXME: Calculate this from `INFOPLIST_FILE`, or create one from `INFOPLIST_KEY_*` settings
                        "infoplists": ["Info.plist"],
                        "deps": [.string(libraryLabel.description)],
                        // FIXME: Give better visibility?
                        "visibility": ["//visibility:public"],
                    ]
                )
            ),
            MetaTarget(
                target: .init(
                    // FIXME: Support multiple languages, including mixed-language
                    kind: .swiftLibrary,
                    label: libraryLabel,
                    singleAttrs: [
                        "module_name": .string(baseName),
                        "srcs": .raw(#"glob(["**/*.swift"])"#),
                    ]
                ),
                intentDefinitions: intentDefinitions,
                canBeTransitiveDep: false
            ),
        ]
    } else if productType == .unitTestBundle {
        let libraryLabel =
            Label(package: package, name: "\(baseName).library")

        targets = [
            MetaTarget(
                target: .init(
                    // FIXME: Do the correct thing based on platform
                    kind: .iOSUnitTest,
                    label: .init(package: package, name: baseName),
                    singleAttrs: [
                        // FIXME: Calculate this from `PRODUCT_BUNDLE_IDENTIFIER`
                        "bundle_id": "org.joinmastodon.MastodonTests",
                        // FIXME: Calculate this from `{PLATFORM}_DEPLOYMENT_TARGET`
                        "minimum_os_version": "16.0",
                    ],
                    listAttrs: [
                        "deps": [.string(libraryLabel.description)],
                        "visibility": ["@rules_xcodeproj//xcodeproj:generated"],
                    ]
                )
            ),
            MetaTarget(
                target: .init(
                    // FIXME: Support multiple languages, including mixed-language
                    kind: .swiftLibrary,
                    label: libraryLabel,
                    singleAttrs: [
                        "module_name": .string(baseName),
                        "srcs": .raw(#"glob(["**/*.swift"])"#),
                    ]
                ),
                intentDefinitions: intentDefinitions,
                canBeTransitiveDep: false
            ),
        ]
    } else if productType == .uiTestBundle {
        let libraryLabel =
            Label(package: package, name: "\(baseName).library")

        targets = [
            MetaTarget(
                target: .init(
                    // FIXME: Do the correct thing based on platform
                    kind: .iOSUITest,
                    label: .init(package: package, name: baseName),
                    singleAttrs: [
                        // FIXME: Calculate this from `PRODUCT_BUNDLE_IDENTIFIER`
                        "bundle_id": "org.joinmastodon.MastodonUITests",
                        // FIXME: Calculate this from `{PLATFORM}_DEPLOYMENT_TARGET`
                        "minimum_os_version": "16.0",
                    ],
                    listAttrs: [
                        "deps": [.string(libraryLabel.description)],
                        "visibility": ["@rules_xcodeproj//xcodeproj:generated"],
                    ]
                )
            ),
            MetaTarget(
                target: .init(
                    // FIXME: Support multiple languages, including mixed-language
                    kind: .swiftLibrary,
                    label: libraryLabel,
                    singleAttrs: [
                        "module_name": .string(baseName),
                        "srcs": .raw(#"glob(["**/*.swift"])"#),
                    ]
                ),
                intentDefinitions: intentDefinitions,
                canBeTransitiveDep: false
            ),
        ]
    } else if productType == .framework {
        let libraryLabel =
            Label(package: package, name: "\(baseName).library")

        targets = [
            MetaTarget(
                target: .init(
                    // FIXME: Do the correct thing based on platform
                    kind: .iOSFramework,
                    label: .init(package: package, name: baseName),
                    listAttrs: [
                        "deps": [.string(libraryLabel.description)],
                        // FIXME: Give better visibility?
                        "visibility": ["//visibility:public"],
                    ]
                )
            ),
            MetaTarget(
                target: .init(
                    // FIXME: Support multiple languages, including mixed-language
                    kind: .swiftLibrary,
                    label: libraryLabel,
                    singleAttrs: [
                        "module_name": .string(baseName),
                        "srcs": .raw(#"glob(["**/*.swift"])"#),
                    ]
                ),
                intentDefinitions: intentDefinitions,
                canBeTransitiveDep: true
            ),
        ]
    } else if productType == .staticLibrary {
        targets = [
            MetaTarget(
                target: .init(
                    // FIXME: Support multiple languages, including mixed-language
                    kind: .swiftLibrary,
                    label: .init(package: package, name: baseName),
                    singleAttrs: ["srcs": .raw(#"glob(["**/*.swift"])"#)],
                    listAttrs: [
                        // FIXME: Give better visibility?
                        "visibility": ["//visibility:public"],
                    ]
                ),
                intentDefinitions: intentDefinitions
            ),
        ]
    } else {
        targets = []

        print("Unsupported product type: \(productType)")
    }

    return targets
}

extension PBXNativeTarget {
    func findPackage() throws -> String {
        var inputFiles = try sourceFiles()
            .compactMap { try $0.fullPath(sourceRoot: "")?.string ?? "" }
            .filter { $0.hasSuffix(".swift") }

        inputFiles.append(
            contentsOf: (buildConfigurationList?.buildConfigurations ?? []).compactMap { config in
                return config.buildSettings["INFOPLIST_FILE"] as? String
            }
        )

        let asComponents = Set(inputFiles)
            .map { $0.split(separator: "/", omittingEmptySubsequences: false) }

        if asComponents.count == 1 {
            return asComponents[0].dropLast().joined(separator: "/")
        }

        let maxComponents = asComponents.map { $0.count }.max() ?? 0
        guard maxComponents > 0 else {
            throw UsageError(message: "Common prefix not found")
        }

        var largestCommon = -1
        for i in (0..<maxComponents) {
            let firstComponent = asComponents[0][i]
            guard asComponents.allSatisfy({ $0[i] == firstComponent }) else {
                break
            }
            largestCommon = i
        }

        guard largestCommon != -1 else {
            throw UsageError(message: """
Common prefix not found among input files of "\(name)": [
\(inputFiles.map { #"    "\#($0)",\#n"# }.joined())\
]
"""
            )
        }

        return asComponents[0][0...largestCommon].joined(separator: "/")
    }
}

extension String {
    var normalizedForLabel: String {
        // FIXME: Change to label-valid (e.g. replace `:` with `_`?)
        return self
    }
}

extension Target {
    mutating func setDeps(_ deps: [Target]) {
        if let mapping = depLabelListMapping[kind] {
            for dep in deps {
                guard let attr = mapping[dep.kind] else {
                    continue
                }

                listAttrs[attr, default: []].append(.string(dep.label.description))
            }
        }

        if let mapping = depLabelMapping[kind] {
            for dep in deps {
                guard let attr = mapping[dep.kind] else {
                    continue
                }

                singleAttrs[attr] = .string(dep.label.description)
            }
        }
    }
}

private let depLabelListMapping: [RuleKind: [RuleKind: String]] = [
    .iOSApplication: [
        .iOSExtension: "extensions",
        .iOSFramework: "frameworks",
    ],
    .iOSFramework: [
        .iOSFramework: "frameworks",
    ],
    .iOSUITest: [
        .iOSFramework: "frameworks",
    ],
    .iOSUnitTest: [
        .iOSFramework: "frameworks",
    ],
    .swiftLibrary: [
        .swiftLibrary: "deps",
    ],
]

private let depLabelMapping: [RuleKind: [RuleKind: String]] = [
    .iOSUITest: [
        .iOSApplication: "test_host",
    ],
    .iOSUnitTest: [
        .iOSApplication: "test_host",
    ],
]

func localSwiftpkgRepo(_ name: String) -> String {
    return "local_swiftpkg_\(name.normalizedForSwiftpkgRepo)"
}

func swiftpkgRepo(_ name: String) -> String {
    return "swiftpkg_\(name.normalizedForSwiftpkgRepo)"
}

extension String {
    var normalizedForSwiftpkgRepo: String {
        return replacingOccurrences(of: "-", with: "_").lowercased()
    }
}

extension RuleKind {
    var isTopLevelTarget: Bool {
        switch self {
        case .appleIntentLibrary: return false
        case .iOSApplication: return true
        case .iOSExtension: return false
        case .iOSFramework: return false
        case .iOSUITest: return true
        case .iOSUnitTest: return true
        case .swiftLibrary: return false
        case .xcodeproj: return false
        case .xcodeprojTopLevelTarget: return false
        }
    }
}
