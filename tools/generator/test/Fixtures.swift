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
        targetMerges: [:],
        invalidTargetMerges: [:],
        extraFiles: [
            .generated("a1b2c/bin/t.c"),
            .generated("a/b/module.modulemap"),
            "a/a.h",
            "a/c.h",
            "a/d/a.h",
            "a/module.modulemap",
            "a/Fram.framework/Fram",
            "a/Fram.framework/Headers/Fram.h",
            "a/StaticFram.framework/StaticFram",
            "a/StaticFram.framework/Headers/StaticFram.h",
        ]
    )

    static let targets: [TargetID: Target] = [
        "A 1": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/A 1",
            product: .init(
                type: .staticLibrary,
                name: "a",
                path: .generated("z/A.a")
            ),
            isSwift: true,
            buildSettings: [
                "PRODUCT_MODULE_NAME": .string("A"),
                "T": .string("42"),
                "Y": .bool(true),
            ],
            inputs: .init(
                srcs: ["x/y.swift"],
                nonArcSrcs: ["b.c"],
                resources: [
                    "Assets.xcassets/Contents.json",
                    "Assets.xcassets/some_image/Contents.json",
                    "Assets.xcassets/some_image/some_image.png",
                ]
            )
        ),
        "A 2": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/A 2",
            product: .init(
                type: .application,
                name: "A",
                path: .generated("z/A.app")
            ),
            buildSettings: [
                "PRODUCT_MODULE_NAME": .string("_Stubbed_A"),
                "T": .string("43"),
                "Z": .string("0")
            ],
            frameworks: ["a/Fram.framework"],
            swiftmodules: [.generated("x/y.swiftmodule")],
            resourceBundles: [.generated("r1/R1.bundle")],
            inputs: .init(
                resources: [
                    "es.lproj/Localized.strings",
                    "es.lproj/Example.strings",
                    "Base.lproj/Example.xib",
                    "en.lproj/Localized.strings",
                    "en.lproj/Example.strings",
                ]
            ),
            links: [
                .generated("a/c.a"),
                .generated("z/A.a"),
            ],
            dependencies: ["C 1", "A 1", "R 1"]
        ),
        "B 1": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/B 1",
            product: .init(
                type: .staticFramework,
                name: "b",
                path: .generated("a/b.framework")
            ),
            modulemaps: ["a/module.modulemap"],
            swiftmodules: [.generated("x/y.swiftmodule")],
            inputs: .init(srcs: ["z.h", "z.mm"], hdrs: ["d.h"]),
            dependencies: ["A 1"]
        ),
        // "B 2" not having a link on "A 1" represents a bundle_loader like
        // relationship. This allows "A 1" to merge into "A 2".
        "B 2": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/B 2",
            product: .init(
                type: .unitTestBundle,
                name: "B",
                path: .generated("B.xctest")
            ),
            testHost: "A 2",
            links: ["a/StaticFram.framework/StaticFram"],
            dependencies: ["A 2", "B 1"]
        ),
        "B 3": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/B 3",
            product: .init(
                type: .uiTestBundle,
                name: "B3",
                path: .generated("B3.xctest")
            ),
            testHost: "A 2",
            links: ["a/StaticFram.framework/StaticFram"],
            dependencies: ["A 2", "B 1"]
        ),
        "C 1": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/C 1",
            product: .init(
                type: .staticLibrary,
                name: "c",
                path: .generated("a/c.a")
            ),
            modulemaps: [.generated("a/b/module.modulemap")],
            inputs: .init(
                srcs: ["a/b/c.m"],
                hdrs: ["a/b/c.h"],
                containsGeneratedFiles: true
            )
        ),
        "C 2": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/C 2",
            product: .init(
                type: .commandLineTool,
                name: "d",
                path: .generated("d")
            ),
            inputs: .init(srcs: ["a/b/d.m"]),
            links: [
                .generated("a/c.a"),
            ],
            dependencies: ["C 1"]
        ),
        "E1": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/E1",
            platform: .init(
                os: .watchOS,
                arch: "x86_64",
                minimumOsVersion: "9.1",
                environment: nil
            ),
            product: .init(
                type: .staticLibrary,
                name: "E1",
                path: .generated("e1/E.a")
            ),
            isSwift: true,
            inputs: .init(srcs: [.external("a_repo/a.swift")])
        ),
        "E2": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/E2",
            platform: .init(
                os: .tvOS,
                arch: "arm64",
                minimumOsVersion: "9.1",
                environment: nil
            ),
            product: .init(
                type: .staticLibrary,
                name: "E2",
                path: .generated("e2/E.a")
            ),
            isSwift: true,
            inputs: .init(srcs: [.external("another_repo/b.swift")])
        ),
        "R 1": Target.mock(
            packageBinDir: "bazel-out/a1b2c/bin/R 1",
            product: .init(
                type: .bundle,
                name: "R 1",
                path: .generated("r1/R1.bundle")
            ),
            inputs: .init(
                resources: [
                    "r1/X.txt",
                    "r1/Assets.xcassets/Contents.json",
                    "r1/Assets.xcassets/image/Contents.json",
                    "r1/Assets.xcassets/image/image.png",
                    .project("r1/nested", isFolder: true),
                    .project("r1/dir", isFolder: true),
                ]
            )
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
        internalDirectoryName: String = "rules_xcodeproj",
        workspaceOutputPath: Path = "some/Project.xcodeproj"
    ) -> (files: [FilePath: File], elements: [FilePath: PBXFileElement]) {
        var elements: [FilePath: PBXFileElement] = [:]

        let linksDir = workspaceOutputPath + internalDirectoryName + "links"

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

        // bazel-out/a/b/module.modulemap

        elements[.generated("a/b/module.modulemap")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.module-map",
            path: "module.modulemap"
        )
        elements[.generated("a/b")] = PBXGroup(
            children: [elements[.generated("a/b/module.modulemap")]!],
            sourceTree: .group,
            path: "b"
        )
        elements[.generated("a")] = PBXGroup(
            children: [elements[.generated("a/b")]!],
            sourceTree: .group,
            path: "a"
        )

        // bazel-out

        elements[.generated("")] = PBXGroup(
            children: [
                elements[.generated("a")]!,
                elements[.generated("a1b2c")]!,
            ],
            sourceTree: .group,
            name: "Bazel Generated Files",
            path: (linksDir + "gen_dir").string
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
            sourceTree: .group,
            name: "Bazel External Repositories",
            path: (linksDir + "external").string
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

        // a/Fram.framework

        elements["a/Fram.framework"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "wrapper.framework",
            path: "Fram.framework"
        )
        elements["a/Fram.framework/Fram"] = elements["a/Fram.framework"]!
        elements["a/Fram.framework/Headers/Fram.h"] =
            elements["a/Fram.framework"]!

        // a/StaticFram.framework

        elements["a/StaticFram.framework"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "wrapper.framework",
            path: "StaticFram.framework"
        )
        elements["a/StaticFram.framework/StaticFram"] =
            elements["a/StaticFram.framework"]!
        elements["a/StaticFram.framework/Headers/StaticFram.h"] =
            elements["a/StaticFram.framework"]!

        // a/module.modulemap

        elements["a/module.modulemap"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.module-map",
            path: "module.modulemap"
        )

        // Parent of the 6 above

        elements["a"] = PBXGroup(
            children: [
                // Folders are before files, then alphabetically
                elements["a/b"]!,
                elements["a/d"]!,
                elements["a/a.h"]!,
                elements["a/c.h"]!,
                elements["a/Fram.framework"]!,
                elements["a/module.modulemap"]!,
                elements["a/StaticFram.framework"]!,
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

        // Assets.xcassets

        elements["Assets.xcassets"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "folder.assetcatalog",
            path: "Assets.xcassets"
        )
        elements["Assets.xcassets/Contents.json"] = elements["Assets.xcassets"]!
        elements["Assets.xcassets/some_image/Contents.json"] =
            elements["Assets.xcassets"]!
        elements["Assets.xcassets/some_image/some_image.png"] =
            elements["Assets.xcassets"]!

        // Localized files

        let en_lproj_example_strings = PBXFileReference(
            sourceTree: .group,
            name: "en",
            lastKnownFileType: "text.plist.strings",
            path: "en.lproj/Example.strings"
        )
        let es_lproj_example_strings = PBXFileReference(
            sourceTree: .group,
            name: "es",
            lastKnownFileType: "text.plist.strings",
            path: "es.lproj/Example.strings"
        )
        let base_lproj_example_xib = PBXFileReference(
            sourceTree: .group,
            name: "Base",
            lastKnownFileType: "file.xib",
            path: "Base.lproj/Example.xib"
        )
        elements["Example.xib"] = PBXVariantGroup(
            children: [
                base_lproj_example_xib,
                en_lproj_example_strings,
                es_lproj_example_strings,
            ],
            sourceTree: .group,
            name: "Example.xib"
        )
        elements["Base.lproj/Example.xib"] = elements["Example.xib"]!
        elements["en.lproj/Example.strings"] = elements["Example.xib"]!
        elements["es.lproj/Example.strings"] = elements["Example.xib"]!

        let en_lproj_localized_strings = PBXFileReference(
            sourceTree: .group,
            name: "en",
            lastKnownFileType: "text.plist.strings",
            path: "en.lproj/Localized.strings"
        )
        let es_lproj_localized_strings = PBXFileReference(
            sourceTree: .group,
            name: "es",
            lastKnownFileType: "text.plist.strings",
            path: "es.lproj/Localized.strings"
        )
        elements["Localized.strings"] = PBXVariantGroup(
            children: [
                en_lproj_localized_strings,
                es_lproj_localized_strings,
            ],
            sourceTree: .group,
            name: "Localized.strings"
        )
        elements["en.lproj/Localized.strings"] = elements["Localized.strings"]!
        elements["es.lproj/Localized.strings"] = elements["Localized.strings"]!

        // r1/X.txt

        elements["r1/X.txt"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "text",
            path: "X.txt"
        )

        // r1/Assets.xcassets

        elements["r1/Assets.xcassets"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "folder.assetcatalog",
            path: "Assets.xcassets"
        )
        elements["r1/Assets.xcassets/Contents.json"] =
            elements["r1/Assets.xcassets"]!
        elements["r1/Assets.xcassets/image/Contents.json"] =
            elements["r1/Assets.xcassets"]!
        elements["r1/Assets.xcassets/image/image.png"] =
            elements["r1/Assets.xcassets"]!

        // r1/nested

        elements[.project("r1/nested", isFolder: true)] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "folder",
            path: "nested"
        )

        // r1/dir

        elements[.project("r1/dir", isFolder: true)] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "folder",
            path: "dir"
        )

        // r1

        elements["r1"] = PBXGroup(
            children: [
                elements[.project("r1/dir", isFolder: true)]!,
                elements[.project("r1/nested", isFolder: true)]!,
                elements["r1/Assets.xcassets"]!,
                elements["r1/X.txt"]!,
            ],
            sourceTree: .group,
            path: "r1"
        )

        // `internal`/CompileStub.swift

        elements[.internal("CompileStub.swift")] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "CompileStub.swift"
        )

        // `internal`

        elements[.internal("")] = PBXGroup(
            children: [
                elements[.internal("CompileStub.swift")]!,
            ],
            sourceTree: .group,
            name: internalDirectoryName,
            path: (workspaceOutputPath + internalDirectoryName).string
        )

        elements.values.forEach { element in
            pbxProj.add(object: element)
            if let variantGroup = element as? PBXVariantGroup {
                variantGroup.children.forEach { pbxProj.add(object: $0) }
            }
        }

        if let group = group {
            // The order files are added to a group matters for uuid fixing
            elements.values.sortedLocalizedStandard().forEach { file in
                if file.parent == nil {
                    group.addChild(file)
                }
            }
        }

        var files: [FilePath: File] = [:]
        for (filePath, element) in elements {
            if let reference = element as? PBXFileReference {
                files[filePath] = .reference(reference)
            } else if let variantGroup = element as? PBXVariantGroup {
                files[filePath] = .variantGroup(variantGroup)
            }
        }

        // xcfilelists

        files[.internal("external.xcfilelist")] = .nonReferencedContent("""
$(BAZEL_EXTERNAL)/a_repo/a.swift
$(BAZEL_EXTERNAL)/another_repo/b.swift

""")

        let genDir = "$(BUILD_DIR)/bazel-out"

        files[.internal("generated.xcfilelist")] = .nonReferencedContent("""
$(BAZEL_OUT)/a/b/module.modulemap
$(BAZEL_OUT)/a1b2c/bin/t.c

""")

        files[.internal("generated.copied.xcfilelist")] = .nonReferencedContent(
"""
$(GEN_DIR)/a/b/module.modulemap
$(GEN_DIR)/a1b2c/bin/t.c

""")

        files[.internal("generated.rsynclist")] = .nonReferencedContent("""
a/b/module.modulemap
a1b2c/bin/t.c

""")

        files[.internal("modulemaps.xcfilelist")] = .nonReferencedContent("""
\(genDir)/a/b/module.modulemap

""")

        files[.internal("modulemaps.fixed.xcfilelist")] = .nonReferencedContent(
"""
\(genDir)/a/b/module.xcode.modulemap

""")

        // LinkFileLists

        files[.internal("targets/a1b2c/A 2/A.LinkFileList")] =
            .nonReferencedContent("""
bazel-out/a/c.a
bazel-out/z/A.a

""")

        files[.internal("targets/a1b2c/C 2/d.LinkFileList")] =
            .nonReferencedContent("""
bazel-out/a/c.a

""")

        return (files, elements)
    }

    static func products(
        in pbxProj: PBXProj,
        parentGroup group: PBXGroup? = nil
    ) -> Products {
        let products = Products([
            Products.ProductKeys(
                target: "A 1",
                filePath: .generated("z/A.a")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "A.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "A 2",
                filePath: .generated("z/A.app")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.application.fileType,
                path: "A.app",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "B 1",
                filePath: .generated("a/b.framework")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticFramework.fileType,
                path: "b.framework",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "B 2",
                filePath: .generated("B.xctest")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.unitTestBundle.fileType,
                path: "B.xctest",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "B 3",
                filePath: .generated("B3.xctest")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.uiTestBundle.fileType,
                path: "B3.xctest",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "C 1",
                filePath: .generated("a/c.a")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "c.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "C 2",
                filePath: .generated("d")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.commandLineTool.fileType,
                path: "d",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "E1",
                filePath: .generated("e1/E.a")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "E.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "E2",
                filePath: .generated("e2/E.a")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.staticLibrary.fileType,
                path: "E.a",
                includeInIndex: false
            ),
            Products.ProductKeys(
                target: "R 1",
                filePath: .generated("r1/R1.bundle")
            ): PBXFileReference(
                sourceTree: .buildProductsDir,
                explicitFileType: PBXProductType.bundle.fileType,
                path: "R1.bundle",
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
                products.byFilePath[.generated("z/A.a")]!,
                products.byFilePath[.generated("z/A.app")]!,
                products.byFilePath[.generated("a/b.framework")]!,
                products.byFilePath[.generated("B.xctest")]!,
                products.byFilePath[.generated("B3.xctest")]!,
                products.byFilePath[.generated("a/c.a")]!,
                products.byFilePath[.generated("d")]!,
                products.byFilePath[.generated("e1/E.a")]!,
                products.byFilePath[.generated("e2/E.a")]!,
                products.byFilePath[.generated("r1/R1.bundle")]!,
            ],
            sourceTree: .group,
            name: "Products"
        )
        pbxProj.add(object: group)

        return group
    }

    static func bazelDependenciesTarget(
        in pbxProj: PBXProj,
        xcodeprojBazelLabel: String
    ) -> PBXAggregateTarget {
        let allPlatforms = """
watchsimulator \
watchos \
macosx \
iphonesimulator \
iphoneos \
driverkit \
appletvsimulator \
appletvos
"""

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "ALLOW_TARGET_PLATFORM_SPECIALIZATION": true,
                "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                "SUPPORTED_PLATFORMS": allPlatforms,
                "SUPPORTS_MACCATALYST": true,
                "TARGET_NAME": "BazelDependencies",
            ]
        )
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)

        let generateFilesScript = PBXShellScriptBuildPhase(
            name: "Generate Files",
            outputFileListPaths: [
                "$(INTERNAL_DIR)/external.xcfilelist",
                "$(INTERNAL_DIR)/generated.xcfilelist",
            ],
            shellScript: #"""
set -eu

if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other
  output_base="$OBJROOT/bazel_output_base"
fi

output_path=$(env -i \
  DEVELOPER_DIR="$DEVELOPER_DIR" \
  HOME="$HOME" \
  PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  USER="$USER" \
  "$BAZEL_PATH" \
  ${output_base:+--output_base "$output_base"} \
  info \
  --experimental_convenience_symlinks=ignore \
  output_path)
external="${output_path%/*/*/*}/external"

# We only want to modify `$LINKS_DIR` during normal builds since Indexing can
# run concurrent to normal builds
if [ "$ACTION" != "indexbuild" ]; then
  mkdir -p "$LINKS_DIR"
  cd "$LINKS_DIR"

  # Add BUILD and DONT_FOLLOW_SYMLINKS_WHEN_TRAVERSING_THIS_DIRECTORY_VIA_A_RECURSIVE_TARGET_PATTERN
  # files to the internal links directory to prevent Bazel from recursing into
  # it, and thus following the `external` symlink
  touch BUILD
  touch DONT_FOLLOW_SYMLINKS_WHEN_TRAVERSING_THIS_DIRECTORY_VIA_A_RECURSIVE_TARGET_PATTERN

  # Need to remove the directories that Xcode creates as part of output prep
  rm -rf external
  rm -rf gen_dir

  ln -sf "$external" external
  ln -sf "$BUILD_DIR/bazel-out" gen_dir
fi

cd "$BUILD_DIR"

rm -rf external
rm -rf real-bazel-out

ln -sf "$external" external
ln -sf "$output_path" real-bazel-out
ln -sfn "$PROJECT_DIR" SRCROOT

# Create parent directories of generated files, so the project navigator works
# better faster

mkdir -p bazel-out
cd bazel-out

sed 's|\/[^\/]*$||' \
  "$INTERNAL_DIR/generated.rsynclist" \
  | uniq \
  | while IFS= read -r dir
do
  mkdir -p "$dir"
done

cd "$SRCROOT"

date +%s > "$INTERNAL_DIR/toplevel_cache_buster"

env -i \
  DEVELOPER_DIR="$DEVELOPER_DIR" \
  HOME="$HOME" \
  PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  USER="$USER" \
  "$BAZEL_PATH" \
  ${output_base:+--output_base "$output_base"} \
  build \
  --experimental_convenience_symlinks=ignore \
  --output_groups=generated_inputs \
  \#(xcodeprojBazelLabel)

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: generateFilesScript)

        let copyFilesScript = PBXShellScriptBuildPhase(
            name: "Copy Files",
            inputFileListPaths: ["$(INTERNAL_DIR)/generated.xcfilelist"],
            outputFileListPaths: [
                "$(INTERNAL_DIR)/generated.copied.xcfilelist",
            ],
            shellScript: #"""
set -eu

cd "$BAZEL_OUT"

# Sync to "$BUILD_DIR/bazel-out". This is the same as "$GEN_DIR" for normal
# builds, but is different for Index Builds. `PBXBuildFile`s will use the
# "$GEN_DIR" version, so indexing might get messed up until they are normally
# generated. It's the best we can do though as we need to use the `gen_dir`
# symlink.
rsync \
  --files-from "$INTERNAL_DIR/generated.rsynclist" \
  --chmod=u+w \
  -L \
  . \
  "$BUILD_DIR/bazel-out"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: copyFilesScript)

        let fixModulemapsScript = PBXShellScriptBuildPhase(
            name: "Fix Modulemaps",
            inputFileListPaths: ["$(INTERNAL_DIR)/modulemaps.xcfilelist"],
            outputFileListPaths: ["$(INTERNAL_DIR)/modulemaps.fixed.xcfilelist"],
            shellScript: #"""
set -eu

while IFS= read -r input; do
  output="${input%.modulemap}.xcode.modulemap"
  perl -p -e \
    's%^(\s*(\w+ )?header )(?!("\.\.(\/\.\.)*\/|")(bazel-out|external)\/)("(\.\.\/)*)(.*")%\1\6SRCROOT/\8%' \
    < "$input" \
    > "$output"
done < "$SCRIPT_INPUT_FILE_LIST_0"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: fixModulemapsScript)

        let pbxProject = pbxProj.rootObject!

        let target = PBXAggregateTarget(
            name: "Bazel Dependencies",
            buildConfigurationList: configurationList,
            buildPhases: [
                generateFilesScript,
                copyFilesScript,
                fixModulemapsScript,
            ],
            productName: "Bazel Dependencies"
        )
        pbxProj.add(object: target)
        pbxProject.targets.append(target)

        let attributes: [String: Any] = [
            "CreatedOnToolsVersion": "13.2.1",
        ]
        pbxProject.setTargetAttributes(
            attributes,
            target: target
        )

        return target
    }

    static func pbxTargets(
        in pbxProj: PBXProj,
        disambiguatedTargets: [TargetID: DisambiguatedTarget],
        files: [FilePath: File],
        products: Products,
        filePathResolver: FilePathResolver,
        bazelDependenciesTarget: PBXAggregateTarget
    ) -> [TargetID: PBXNativeTarget] {
        // Build phases

        func createGeneratedHeaderShellScript() -> PBXShellScriptBuildPhase {
            let shellScript = PBXShellScriptBuildPhase(
                name: "Copy Swift Generated Header",
                inputPaths: [
                    "$(DERIVED_FILE_DIR)/$(SWIFT_OBJC_INTERFACE_HEADER_NAME)",
                ],
                outputPaths: [
                    "$(CONFIGURATION_BUILD_DIR)/$(SWIFT_OBJC_INTERFACE_HEADER_NAME)",
                ],
                shellScript: #"""
    cp "${SCRIPT_INPUT_FILE_0}" "${SCRIPT_OUTPUT_FILE_0}"

    """#,
                showEnvVarsInLog: false
            )
            pbxProj.add(object: shellScript)
            return shellScript
        }

        func buildFiles(_ buildFiles: [PBXBuildFile]) -> [PBXBuildFile] {
            buildFiles.forEach { pbxProj.add(object: $0) }
            return buildFiles
        }

        let elements = files.mapValues(\.fileElement)

        let buildPhases: [TargetID: [PBXBuildPhase]] = [
            "A 1": [
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["x/y.swift"]!),
                        PBXBuildFile(
                            file: elements["b.c"]!,
                            settings: ["COMPILER_FLAGS": "-fno-objc-arc"]
                        ),
                    ])
                ),
                createGeneratedHeaderShellScript(),
            ],
            "A 2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.internal("CompileStub.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements["a/Fram.framework"]!
                    )])
                ),
                PBXResourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["Example.xib"]!),
                        PBXBuildFile(file: elements["Localized.strings"]!),
                        PBXBuildFile(file: products
                            .byFilePath[.generated("r1/R1.bundle")]!
                        ),
                    ])
                ),
                PBXCopyFilesBuildPhase(
                    dstPath: "",
                    dstSubfolderSpec: .frameworks,
                    name: "Embed Frameworks",
                    files: buildFiles([PBXBuildFile(
                        file: elements["a/Fram.framework"]!,
                        settings: ["ATTRIBUTES": [
                            "CodeSignOnCopy",
                            "RemoveHeadersOnCopy",
                        ]]
                    )])
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
            ],
            "B 2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.internal("CompileStub.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements["a/StaticFram.framework"]!
                    )])
                ),
            ],
            "B 3": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.internal("CompileStub.swift")]!
                    )])
                ),
                PBXFrameworksBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements["a/StaticFram.framework"]!
                    )])
                ),
            ],
            "C 1": [
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["a/b/c.m"]!),
                    ])
                ),
            ],
            "C 2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(file: elements["a/b/d.m"]!),
                    ])
                ),
            ],
            "E1": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.external("a_repo/a.swift")]!),
                    ])
                ),
                createGeneratedHeaderShellScript(),
            ],
            "E2": [
                PBXSourcesBuildPhase(
                    files: buildFiles([PBXBuildFile(
                        file: elements[.external("another_repo/b.swift")]!
                    )])
                ),
                createGeneratedHeaderShellScript(),
            ],
            "R 1": [
                PBXResourcesBuildPhase(
                    files: buildFiles([
                        PBXBuildFile(
                            file: elements["r1/Assets.xcassets"]!
                        ),
                        PBXBuildFile(
                            file: elements[.project("r1/dir", isFolder: true)]!
                        ),
                        PBXBuildFile(
                            file: elements[
                                .project("r1/nested", isFolder: true)
                            ]!
                        ),
                        PBXBuildFile(
                            file: elements["r1/X.txt"]!
                        ),
                    ])
                ),
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
            "R 1": PBXNativeTarget(
                name: disambiguatedTargets["R 1"]!.name,
                buildPhases: buildPhases["R 1"] ?? [],
                productName: "R 1",
                product: products.byTarget["R 1"],
                productType: .bundle
            ),
        ]

        _ = try! pbxTargets["A 1"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["A 2"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["B 1"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["B 2"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["B 3"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["C 1"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["C 2"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["E1"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["E2"]!.addDependency(
            target: bazelDependenciesTarget
        )
        _ = try! pbxTargets["R 1"]!.addDependency(
            target: bazelDependenciesTarget
        )

        // The order target are added to `PBXProject`s matter for uuid fixing.
        for pbxTarget in pbxTargets.values.sortedLocalizedStandard(\.name) {
            pbxProj.add(object: pbxTarget)
            pbxProj.rootObject!.targets.append(pbxTarget)
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

        let internalDirectoryName = "rules_xcp"
        let workspaceOutputPath: Path = "Project.xcodeproj"

        let filePathResolver = FilePathResolver(
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let bazelDependenciesTarget = Fixtures.bazelDependenciesTarget(
            in: pbxProj,
            xcodeprojBazelLabel: ""
        )

        let disambiguatedTargets = Fixtures.disambiguatedTargets(targets)
        let pbxTargets = Fixtures.pbxTargets(
            in: pbxProj,
            disambiguatedTargets: disambiguatedTargets,
            files: files,
            products: products,
            filePathResolver: filePathResolver,
            bazelDependenciesTarget: bazelDependenciesTarget
        )

        return (pbxTargets, disambiguatedTargets)
    }

    static func pbxTargetsWithConfigurations(
        in pbxProj: PBXProj,
        targets: [TargetID: Target]
    ) -> [TargetID: PBXNativeTarget] {
        let (pbxTargets, _) = Fixtures.pbxTargets(
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
            "R 1": baseAttributes,
        ]

        let pbxProject = pbxProj.rootObject!
        for (id, targetAttributes) in attributes {
            let pbxTarget = pbxTargets[id]!
            pbxProject.setTargetAttributes(targetAttributes, target: pbxTarget)
        }

        let buildSettings: [TargetID: [String: Any]] = [
            "A 1": targets["A 1"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/A 1",
                "GENERATE_INFOPLIST_FILE": true,
                "SDKROOT": "macosx",
                "TARGET_NAME": targets["A 1"]!.name,
            ]) { $1 },
            "A 2": targets["A 2"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/A 2",
                "GENERATE_INFOPLIST_FILE": true,
                "LD_RUNPATH_SEARCH_PATHS": [
                    "$(inherited)",
                    "@executable_path/../Frameworks",
                ],
                "OTHER_LDFLAGS": [
                    "-filelist",
                    #"""
"$(INTERNAL_DIR)/targets/a1b2c/A 2/A.LinkFileList,$(BUILD_DIR)"
"""#,
                ],
                "SDKROOT": "macosx",
                "SWIFT_INCLUDE_PATHS": "$(BUILD_DIR)/bazel-out/x",
                "TARGET_NAME": targets["A 2"]!.name,
            ]) { $1 },
            "B 1": targets["B 1"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/B 1",
                "GENERATE_INFOPLIST_FILE": true,
                "OTHER_SWIFT_FLAGS": """
-Xcc -fmodule-map-file=$(PROJECT_DIR)/a/module.modulemap
""",
                "SDKROOT": "macosx",
                "SWIFT_INCLUDE_PATHS": "$(BUILD_DIR)/bazel-out/x",
                "TARGET_NAME": targets["B 1"]!.name,
            ]) { $1 },
            "B 2": targets["B 2"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/B 2",
                "BUNDLE_LOADER": "$(TEST_HOST)",
                "GENERATE_INFOPLIST_FILE": true,
                "OTHER_LDFLAGS": [
                    "-filelist",
                    #"""
"$(INTERNAL_DIR)/targets/a1b2c/B 2/B.LinkFileList,$(BUILD_DIR)"
"""#,
                ],
                "SDKROOT": "macosx",
                "TARGET_BUILD_DIR": """
$(BUILD_DIR)/bazel-out/a1b2c/bin/A 2$(TARGET_BUILD_SUBPATH)
""",
                "TARGET_NAME": targets["B 2"]!.name,
                "TEST_HOST": "$(BUILD_DIR)/bazel-out/a1b2c/bin/A 2/A.app/A",
            ]) { $1 },
            "B 3": targets["B 3"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/B 3",
                "GENERATE_INFOPLIST_FILE": true,
                "OTHER_LDFLAGS": [
                    "-filelist",
                    #"""
"$(INTERNAL_DIR)/targets/a1b2c/B 3/B3.LinkFileList,$(BUILD_DIR)"
"""#,
                ],
                "SDKROOT": "macosx",
                "TARGET_NAME": targets["B 3"]!.name,
                "TEST_TARGET_NAME": pbxTargets["A 2"]!.name,
            ]) { $1 },
            "C 1": targets["C 1"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/C 1",
                "GENERATE_INFOPLIST_FILE": true,
                "OTHER_SWIFT_FLAGS": """
-Xcc -fmodule-map-file=$(BUILD_DIR)/bazel-out/a/b/module.xcode.modulemap
""",
                "SDKROOT": "macosx",
                "TARGET_NAME": targets["C 1"]!.name,
            ]) { $1 },
            "C 2": targets["C 2"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/C 2",
                "GENERATE_INFOPLIST_FILE": true,
                "OTHER_LDFLAGS": [
                    "-Wl,-rpath,/usr/lib/swift",
                    """
-L$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)
""",
                    "-L/usr/lib/swift",
                    "-filelist",
                    #"""
"$(INTERNAL_DIR)/targets/a1b2c/C 2/d.LinkFileList,$(BUILD_DIR)"
"""#,
                ],
                "SDKROOT": "macosx",
                "TARGET_NAME": targets["C 2"]!.name,
            ]) { $1 },
            "E1": targets["E1"]!.buildSettings.asDictionary.merging([
                "ARCHS": "x86_64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/E1",
                "GENERATE_INFOPLIST_FILE": true,
                "SDKROOT": "watchos",
                "TARGET_NAME": targets["E1"]!.name,
            ]) { $1 },
            "E2": targets["E2"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/E2",
                "GENERATE_INFOPLIST_FILE": true,
                "SDKROOT": "appletvos",
                "TARGET_NAME": targets["E2"]!.name,
            ]) { $1 },
            "R 1": targets["R 1"]!.buildSettings.asDictionary.merging([
                "ARCHS": "arm64",
                "BAZEL_PACKAGE_BIN_DIR": "bazel-out/a1b2c/bin/R 1",
                "GENERATE_INFOPLIST_FILE": true,
                "SDKROOT": "macosx",
                "TARGET_NAME": targets["R 1"]!.name,
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
        _ = try! pbxTargets["A 2"]!.addDependency(target: pbxTargets["R 1"]!)
        _ = try! pbxTargets["B 1"]!.addDependency(target: pbxTargets["A 1"]!)
        _ = try! pbxTargets["B 2"]!.addDependency(target: pbxTargets["A 2"]!)
        _ = try! pbxTargets["B 2"]!.addDependency(target: pbxTargets["B 1"]!)
        _ = try! pbxTargets["B 3"]!.addDependency(target: pbxTargets["A 2"]!)
        _ = try! pbxTargets["B 3"]!.addDependency(target: pbxTargets["B 1"]!)
        _ = try! pbxTargets["C 2"]!.addDependency(target: pbxTargets["C 1"]!)

        return pbxTargets
    }
}
