import Foundation
import PathKit
import XcodeProj

@testable import generator

enum Fixtures {
    static let project = Project(
        name: "Bazel",
        label: "//:xcodeproj",
        buildSettings: [
            "ALWAYS_SEARCH_USER_PATHS": .bool(false),
            "COPY_PHASE_STRIP": .bool(false),
            "ONLY_ACTIVE_ARCH": .bool(true),
        ],
        targets: targets,
        potentialTargetMerges: [:],
        requiredLinks: [],
        extraFiles: [
            .generated("a1b2c/bin/t.c"),
            "a/a.h",
            "a/c.h",
            "a/d/a.h",
            "a/module.modulemap",
            "Assets.xcassets/Contents.json",
        ]
    )

    static let targets: [TargetID: Target] = [
        "A 1": Target.mock(
            product: .init(type: .staticLibrary, name: "a", path: "z/A.a"),
            buildSettings: [
                "PRODUCT_MODULE_NAME": .string("A"),
                "T": .string("42"),
                "Y": .bool(true),
            ],
            inputs: .init(srcs: ["x/y.swift"], nonArcSrcs: ["b.c"])
        ),
        "A 2": Target.mock(
            product: .init(type: .application, name: "A", path: "z/A.app"),
            buildSettings: [
                "PRODUCT_MODULE_NAME": .string("_Stubbed_A"),
                "T": .string("43"),
                "Z": .string("0")
            ],
            links: ["a/c.a", "z/A.a"],
            dependencies: ["C 1", "A 1"]
        ),
        "B 1": Target.mock(
            product: .init(
                type: .staticFramework,
                name: "b",
                path: "a/b.framework"
            ),
            modulemaps: ["a/module.modulemap"],
            inputs: .init(srcs: ["z.h", "z.mm"], hdrs: ["d.h"]),
            dependencies: ["A 1"]
        ),
        // "B 2" not having a link on "A 1" represents a bundle_loader like
        // relationship. This allows "A 1" to merge into "A 2".
        "B 2": Target.mock(
            product: .init(type: .unitTestBundle, name: "B", path: "B.xctest"),
            testHost: "A 2",
            links: ["a/b.framework"],
            dependencies: ["A 2", "B 1"]
        ),
        "B 3": Target.mock(
            product: .init(type: .uiTestBundle, name: "B3", path: "B3.xctest"),
            testHost: "A 2",
            links: ["a/b.framework"],
            dependencies: ["A 2", "B 1"]
        ),
        "C 1": Target.mock(
            product: .init(type: .staticLibrary, name: "c", path: "a/c.a"),
            modulemaps: [.generated("a/b/module.modulemap")],
            inputs: .init(srcs: ["a/b/c.m"], hdrs: ["a/b/c.h"])
        ),
        "C 2": Target.mock(
            product: .init(type: .commandLineTool, name: "d", path: "d"),
            inputs: .init(srcs: ["a/b/d.m"]),
            links: ["a/c.a"],
            dependencies: ["C 1"]
        ),
        "E1": Target.mock(
            product: .init(type: .staticLibrary, name: "E1", path: "e1/E.a"),
            inputs: .init(srcs: [.external("a_repo/a.swift")])
        ),
        "E2": Target.mock(
            product: .init(type: .staticLibrary, name: "E2", path: "e2/E.a"),
            inputs: .init(srcs: [.external("another_repo/b.swift")])
        ),
    ]

    static func disambiguatedTargets(
        _ targets: [TargetID: Target]
    ) -> [TargetID: DisambiguatedTarget] {
        var disambiguatedTargets = Dictionary<TargetID, DisambiguatedTarget>(
            minimumCapacity: targets.count
        )
        for (id, target) in targets {
            disambiguatedTargets[id] = DisambiguatedTarget(
                name: "\(id.rawValue) (Distinguished)",
                nameBuildSetting: Data(id.rawValue.utf8).base64EncodedString(),
                target: target
            )
        }
        return disambiguatedTargets
    }

    static func pbxProj() -> PBXProj {
        let pbxProj = PBXProj()

        let mainGroup = PBXGroup(sourceTree: .group)
        pbxProj.add(object: mainGroup)

        let buildConfigurationList = XCConfigurationList()
        pbxProj.add(object: buildConfigurationList)

        let pbxProject = PBXProject(
            name: "Project",
            buildConfigurationList: buildConfigurationList,
            compatibilityVersion: "Xcode 13.0",
            mainGroup: mainGroup
        )
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        return pbxProj
    }

    static func files(
        in pbxProj: PBXProj,
        parentGroup group: PBXGroup? = nil,
        externalDirectory: Path = "/var/tmp/_bazel_U/HASH/external",
        generatedDirectory: Path = "/var/tmp/_bazel_U/H/execroot/W/bazel-out",
        internalDirectoryName: String = "rules_xcodeproj",
        workspaceOutputPath: Path = "some/Project.xcodeproj"
    ) -> (files: [FilePath: File], elements: [FilePath: PBXFileElement]) {
        var elements: [FilePath: PBXFileElement] = [:]

        // bazel-out/a1b2c/bin/t.c

        elements[.generated("a1b2c/bin/t.c")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.c",
            path: "t.c"
        )
        elements[.generated("a1b2c/bin")] = PBXGroup(
            children: [elements[.generated("a1b2c/bin/t.c")]!],
            sourceTree: .group,
            path: "bin"
        )
        elements[.generated("a1b2c")] = PBXGroup(
            children: [elements[.generated("a1b2c/bin")]!],
            sourceTree: .group,
            path: "a1b2c"
        )
        elements[.generated("")] = PBXGroup(
            children: [elements[.generated("a1b2c")]!],
            sourceTree: .absolute,
            name: "Bazel Generated Files",
            path: generatedDirectory.string
        )

        // external/a_repo/a.swift

        elements[.external("a_repo/a.swift")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "a.swift"
        )
        elements[.external("a_repo")] = PBXGroup(
            children: [elements[.external("a_repo/a.swift")]!],
            sourceTree: .group,
            path: "a_repo"
        )

        // external/another_repo/b.swift

        elements[.external("another_repo/b.swift")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "b.swift"
        )
        elements[.external("another_repo")] = PBXGroup(
            children: [elements[.external("another_repo/b.swift")]!],
            sourceTree: .group,
            path: "another_repo"
        )

        // external

        elements[.external("")] = PBXGroup(
            children: [
                elements[.external("a_repo")]!,
                elements[.external("another_repo")]!,
            ],
            sourceTree: .absolute,
            name: "Bazel External Repositories",
            path: externalDirectory.string
        )

        // a/a.h

        elements["a/a.h"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.h",
            path: "a.h"
        )

        // a/c.h

        elements["a/c.h"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.h",
            path: "c.h"
        )

        // a/d/a.h

        elements["a/d/a.h"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.h",
            path: "a.h"
        )
        elements["a/d"] = PBXGroup(
            children: [elements["a/d/a.h"]!],
            sourceTree: .group,
            path: "d"
        )

        // a/b/c.h

        elements["a/b/c.h"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.h",
            path: "c.h"
        )

        // a/b/c.m

        elements["a/b/c.m"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.objc",
            path: "c.m"
        )

        // a/b/d.m

        elements["a/b/d.m"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.objc",
            path: "d.m"
        )

        // a/b

        elements["a/b"] = PBXGroup(
            children: [
                elements["a/b/c.h"]!,
                elements["a/b/c.m"]!,
                elements["a/b/d.m"]!,
            ],
            sourceTree: .group,
            path: "b"
        )

        // a/module.modulemap

        elements["a/module.modulemap"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.module-map",
            path: "module.modulemap"
        )

        // Parent of the 5 above

        elements["a"] = PBXGroup(
            children: [
                // Folders are before files, then alphabetically
                elements["a/b"]!,
                elements["a/d"]!,
                elements["a/a.h"]!,
                elements["a/c.h"]!,
                elements["a/module.modulemap"]!,
            ],
            sourceTree: .group,
            path: "a"
        )

        // b.c

        elements["b.c"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.c",
            path: "b.c"
        )

        // d.h

        elements["d.h"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.h",
            path: "d.h"
        )

        // x/y.swift

        elements["x/y.swift"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "y.swift"
        )
        elements["x"] = PBXGroup(
            children: [elements["x/y.swift"]!],
            sourceTree: .group,
            path: "x"
        )

        // z.h

        elements["z.h"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.h",
            path: "z.h"
        )

        // z.mm

        elements["z.mm"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.cpp.objcpp",
            path: "z.mm"
        )

        // Assets.xcassets/Contents.json

        elements["Assets.xcassets"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "folder.assetcatalog",
            path: "Assets.xcassets"
        )

        // `internal`/CompileStub.swift

        elements[.internal("CompileStub.swift")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "CompileStub.swift"
        )

        // `internal`/generated.xcfilelist

        elements[.internal("generated.xcfilelist")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "text.xcfilelist",
            path: "generated.xcfilelist"
        )

        // `internal`

        elements[.internal("")] = PBXGroup(
            children: [
                elements[.internal("CompileStub.swift")]!,
                elements[.internal("generated.xcfilelist")]!,
            ],
            sourceTree: .group,
            name: internalDirectoryName,
            path: (workspaceOutputPath + internalDirectoryName).string
        )

        elements.values.forEach { pbxProj.add(object: $0) }

        if let group = group {
            // The order files are added to a group matters for uuid fixing
            elements.values.sortedLocalizedStandard().forEach { file in
                if file is PBXGroup || file.parent == nil {
                    group.addChild(file)
                }
            }
        }

        var files: [FilePath: File] = [:]
        for (filePath, element) in elements {
            guard let reference = element as? PBXFileReference else {
                continue
            }

            let content: String
            if filePath == .internal("generated.xcfilelist") {
                content = """
\(generatedDirectory)/a/b/module.modulemap
\(generatedDirectory)/a1b2c/bin/t.c

"""
            } else {
                content = ""
            }
            
            files[filePath] = File(reference: reference, content: content)
        }

        return (files, elements)
    }

    static func products(
        in pbxProj: PBXProj,
        parentGroup group: PBXGroup? = nil
    ) -> Products {
        let products = Products([
            Products.ProductKeys(
                target: "A 1",
                path: "z/A.a"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "A.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "A 2",
                path: "z/A.app"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.application.fileType,
                path: "A.app",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "B 1",
                path: "a/b.framework"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticFramework.fileType,
                path: "b.framework",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "B 2",
                path: "B.xctest"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.unitTestBundle.fileType,
                path: "B.xctest",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "B 3",
                path: "B3.xctest"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.uiTestBundle.fileType,
                path: "B3.xctest",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "C 1",
                path: "a/c.a"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "c.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "C 2",
                path: "d"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.commandLineTool.fileType,
                path: "d",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "E1",
                path: "e1/E.a"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "E.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "E2",
                path: "e2/E.a"
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "E.a",
                includeInIndex: false
            ),
        ])
        products.byTarget.values.forEach { pbxProj.add(object: $0) }

        if let group = group {
            // The order products are added to a group matters for uuid fixing
            products.byTarget.sortedLocalizedStandard().forEach { product in
                group.addChild(product)
            }
        }

        return products
    }

    static func productsGroup(
        in pbxProj: PBXProj, products: Products
    ) -> PBXGroup {
        let group = PBXGroup(
            children: [
                products.byPath["z/A.a"]!,
                products.byPath["z/A.app"]!,
                products.byPath["a/b.framework"]!,
                products.byPath["B.xctest"]!,
                products.byPath["B3.xctest"]!,
                products.byPath["a/c.a"]!,
                products.byPath["d"]!,
                products.byPath["e1/E.a"]!,
                products.byPath["e2/E.a"]!,
            ],
            sourceTree: .group,
            name: "Products"
        )
        pbxProj.add(object: group)

        return group
    }

    static func pbxTargets(
        in pbxProj: PBXProj,
        disambiguatedTargets: [TargetID: DisambiguatedTarget],
        files: [FilePath: File],
        products: Products,
        xcodeprojBazelLabel: String
    ) -> [TargetID: PBXNativeTarget] {
        // Build phases

        func buildFiles(_ buildFiles: [PBXBuildFile]) -> [PBXBuildFile] {
            buildFiles.forEach { pbxProj.add(object: $0) }
            return buildFiles
        }

        let elements = files.mapValues(\.reference)

        let buildPhases: [TargetID: [PBXBuildPhase]] = [
            "A 1": [
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(
                            file: elements["b.c"]!,
                            settings: ["COMPILER_FLAGS": "-fno-objc-arc"]
                        ),
                        PBXBuildFile(file: elements["x/y.swift"]!),
                    ])
                ),
                PBXFrameworksBuildPhase(),
            ],
            "A 2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.internal("CompileStub.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: products.byTarget["A 1"]!),
                        PBXBuildFile(file: products.byTarget["C 1"]!),
                    ])
                ),
            ],
            "B 1": [
                PBXHeadersBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(
                            file: elements["d.h"]!,
                            settings: ["ATTRIBUTES": ["Public"]]
                        ),
                        PBXBuildFile(file: elements["z.h"]!),
                    ])
                ),
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["z.h"]!),
                        PBXBuildFile(file: elements["z.mm"]!),
                    ])
                ),
                PBXFrameworksBuildPhase(),
            ],
            "B 2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.internal("CompileStub.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: products.byTarget["B 1"]!),
                    ])
                ),
            ],
            "B 3": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.internal("CompileStub.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: products.byTarget["B 1"]!),
                    ])
                ),
            ],
            "C 1": [
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["a/b/c.m"]!),
                    ])
                ),
                PBXFrameworksBuildPhase(),
            ],
            "C 2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["a/b/d.m"]!),
                    ])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: products.byTarget["C 1"]!),
                    ])
                ),
            ],
            "E1": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.external("a_repo/a.swift")]!),
                    ])
                ),
                PBXFrameworksBuildPhase(),
            ],
            "E2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.external("another_repo/b.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(),
            ],
        ]
        buildPhases.values.forEach { buildPhases in
            buildPhases.forEach { pbxProj.add(object: $0) }
        }

        // Targets

        let pbxTargets: [TargetID: PBXNativeTarget] = [
            "A 1": PBXNativeTarget(
                name: disambiguatedTargets["A 1"]!.name,
                buildPhases: buildPhases["A 1"] ?? [],
                productName: "a",
                product: products.byTarget["A 1"],
                productType: .staticLibrary
            ),
            "A 2": PBXNativeTarget(
                name: disambiguatedTargets["A 2"]!.name,
                buildPhases: buildPhases["A 2"] ?? [],
                productName: "A",
                product: products.byTarget["A 2"],
                productType: .application
            ),
            "B 1": PBXNativeTarget(
                name: disambiguatedTargets["B 1"]!.name,
                buildPhases: buildPhases["B 1"] ?? [],
                productName: "b",
                product: products.byTarget["B 1"],
                productType: .staticFramework
            ),
            "B 2": PBXNativeTarget(
                name: disambiguatedTargets["B 2"]!.name,
                buildPhases: buildPhases["B 2"] ?? [],
                productName: "B",
                product: products.byTarget["B 2"],
                productType: .unitTestBundle
            ),
            "B 3": PBXNativeTarget(
                name: disambiguatedTargets["B 3"]!.name,
                buildPhases: buildPhases["B 3"] ?? [],
                productName: "B3",
                product: products.byTarget["B 3"],
                productType: .uiTestBundle
            ),
            "C 1": PBXNativeTarget(
                name: disambiguatedTargets["C 1"]!.name,
                buildPhases: buildPhases["C 1"] ?? [],
                productName: "c",
                product: products.byTarget["C 1"],
                productType: .staticLibrary
            ),
            "C 2": PBXNativeTarget(
                name: disambiguatedTargets["C 2"]!.name,
                buildPhases: buildPhases["C 2"] ?? [],
                productName: "d",
                product: products.byTarget["C 2"],
                productType: .commandLineTool
            ),
            "E1": PBXNativeTarget(
                name: disambiguatedTargets["E1"]!.name,
                buildPhases: buildPhases["E1"] ?? [],
                productName: "E1",
                product: products.byTarget["E1"],
                productType: .staticLibrary
            ),
            "E2": PBXNativeTarget(
                name: disambiguatedTargets["E2"]!.name,
                buildPhases: buildPhases["E2"] ?? [],
                productName: "E2",
                product: products.byTarget["E2"],
                productType: .staticLibrary
            ),
        ]

        let pbxProject = pbxProj.rootObject!

        let debugConfiguration = XCBuildConfiguration(name: "Debug")
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)
        let shellScript = PBXShellScriptBuildPhase(
            outputFileListPaths: [
                files[.internal("generated.xcfilelist")]!
                    .reference
                    .projectRelativePath(in: pbxProj)
                    .string,
            ],
            shellScript: #"""
PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  ${BAZEL_PATH} \
  build \
  --output_groups=generated_inputs \
  \#(xcodeprojBazelLabel)

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: shellScript)
        let generatedFilesTarget = PBXAggregateTarget(
            name: "Bazel Generated Files",
            buildConfigurationList: configurationList,
            buildPhases: [shellScript],
            productName: "Bazel Generated Files"
        )
        pbxProj.add(object: generatedFilesTarget)
        pbxProject.targets.append(generatedFilesTarget)

        let attributes: [String: Any] = [
            "CreatedOnToolsVersion": "13.2.1",
        ]
        pbxProject.setTargetAttributes(attributes, target: generatedFilesTarget)

        _ = try! pbxTargets["C 1"]!.addDependency(target: generatedFilesTarget)

        // The order target are added to `PBXProject`s matter for uuid fixing.
        for pbxTarget in pbxTargets.values.sortedLocalizedStandard(\.name) {
            pbxProj.add(object: pbxTarget)
            pbxProject.targets.append(pbxTarget)
        }

        return pbxTargets
    }

    static func pbxTargets(
        in pbxProj: PBXProj,
        targets: [TargetID: Target]
    ) -> ([TargetID: PBXNativeTarget], [TargetID : DisambiguatedTarget]) {
        let pbxProject = pbxProj.rootObject!
        let mainGroup = pbxProject.mainGroup!

        let (files, _) = Fixtures.files(in: pbxProj, parentGroup: mainGroup)
        let products = Fixtures.products(in: pbxProj, parentGroup: mainGroup)

        let disambiguatedTargets = Fixtures.disambiguatedTargets(targets)

        let pbxTargets = Fixtures.pbxTargets(
            in: pbxProj,
            disambiguatedTargets: disambiguatedTargets,
            files: files,
            products: products,
            xcodeprojBazelLabel: ""
        )

        return (pbxTargets, disambiguatedTargets)
    }

    static func pbxTargetsWithConfigurations(
        in pbxProj: PBXProj,
        targets: [TargetID: Target]
    ) -> [TargetID: PBXNativeTarget] {
        let (pbxTargets, distinguished) = Fixtures.pbxTargets(
            in: pbxProj,
            targets: targets
        )

        let baseAttributes: [String: Any] = [
            "CreatedOnToolsVersion": "13.2.1",
            "LastSwiftMigration": 1320,
        ]

        let attributes: [TargetID: [String: Any]] = [
            "A 1": baseAttributes,
            "A 2": baseAttributes,
            "B 1": baseAttributes,
            "B 2": baseAttributes.merging([
                "TestTargetID": pbxTargets["A 2"]!,
            ]) { $1 },
            "B 3": baseAttributes.merging([
                "TestTargetID": pbxTargets["A 2"]!,
            ]) { $1 },
            "C 1": baseAttributes,
            "C 2": baseAttributes,
            "E1": baseAttributes,
            "E2": baseAttributes,
        ]

        let pbxProject = pbxProj.rootObject!
        for (id, targetAttributes) in attributes {
            let pbxTarget = pbxTargets[id]!
            pbxProject.setTargetAttributes(targetAttributes, target: pbxTarget)
        }

        let buildSettings: [TargetID: [String: Any]] = [
            "A 1": targets["A 1"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["A 1"]!.nameBuildSetting,
            ]) { $1 },
            "A 2": targets["A 2"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["A 2"]!.nameBuildSetting,
            ]) { $1 },
            "B 1": targets["B 1"]!.buildSettings.asDictionary.merging([
                "OTHER_SWIFT_FLAGS": """
-Xcc -fmodule-map-file=a/module.modulemap
""",
                "TARGET_NAME": distinguished["B 1"]!.nameBuildSetting,
            ]) { $1 },
            "B 2": targets["B 2"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["B 2"]!.nameBuildSetting,
                "BUNDLE_LOADER": "$(TEST_HOST)",
                "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/A.app/A",
            ]) { $1 },
            "B 3": targets["B 3"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["B 3"]!.nameBuildSetting,
                "TEST_TARGET_NAME": pbxTargets["A 2"]!.name,
            ]) { $1 },
            "C 1": targets["C 1"]!.buildSettings.asDictionary.merging([
                "OTHER_SWIFT_FLAGS": """
-Xcc -fmodule-map-file=bazel-out/a/b/module.modulemap
""",
                "TARGET_NAME": distinguished["C 1"]!.nameBuildSetting,
            ]) { $1 },
            "C 2": targets["C 2"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["C 2"]!.nameBuildSetting,
            ]) { $1 },
            "E1": targets["E1"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["E1"]!.nameBuildSetting,
            ]) { $1 },
            "E2": targets["E2"]!.buildSettings.asDictionary.merging([
                "TARGET_NAME": distinguished["E2"]!.nameBuildSetting,
            ]) { $1 },
        ]
        for (id, buildSettings) in buildSettings {
            let debugConfiguration = XCBuildConfiguration(
                name: "Debug",
                buildSettings: buildSettings
            )
            pbxProj.add(object: debugConfiguration)
            let configurationList = XCConfigurationList(
                buildConfigurations: [debugConfiguration],
                defaultConfigurationName: debugConfiguration.name
            )
            pbxProj.add(object: configurationList)
            pbxTargets[id]!.buildConfigurationList = configurationList
        }

        return pbxTargets
    }

    static func pbxTargetsWithDependencies(
        in pbxProj: PBXProj,
        targets: [TargetID: Target]
    ) -> [TargetID: PBXNativeTarget] {
        let (pbxTargets, _) = Fixtures.pbxTargets(in: pbxProj, targets: targets)

        _ = try! pbxTargets["A 2"]!.addDependency(target: pbxTargets["A 1"]!)
        _ = try! pbxTargets["A 2"]!.addDependency(target: pbxTargets["C 1"]!)
        _ = try! pbxTargets["B 1"]!.addDependency(target: pbxTargets["A 1"]!)
        _ = try! pbxTargets["B 2"]!.addDependency(target: pbxTargets["A 2"]!)
        _ = try! pbxTargets["B 2"]!.addDependency(target: pbxTargets["B 1"]!)
        _ = try! pbxTargets["B 3"]!.addDependency(target: pbxTargets["A 2"]!)
        _ = try! pbxTargets["B 3"]!.addDependency(target: pbxTargets["B 1"]!)
        _ = try! pbxTargets["C 2"]!.addDependency(target: pbxTargets["C 1"]!)

        return pbxTargets
    }
}
