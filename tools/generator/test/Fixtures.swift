import PathKit
import XcodeProj

@testable import generator

enum Fixtures {
    static let project = Project(
        name: "Bazel",
        buildSettings: [
            "ALWAYS_SEARCH_USER_PATHS": .bool(false),
            "COPY_PHASE_STRIP": .bool(false),
            "ONLY_ACTIVE_ARCH": .bool(true),
        ],
        targets: targets,
        potentialTargetMerges: [:],
        requiredLinks: [],
        extraFiles: [
            "a/a.h",
            "a/c.h",
            "a/d/a.h",
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
            srcs: ["x/y.swift", "b.c"]
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
            product: .init(type: .staticLibrary, name: "b", path: "a/b.a"),
            srcs: ["z.mm"],
            dependencies: ["A 1"]
        ),
        // "B 2" not having a link on "A 1" represents a bundle_loader like
        // relationship. This allows "A 1" to merge into "A 2".
        "B 2": Target.mock(
            product: .init(type: .unitTestBundle, name: "B", path: "B.xctest"),
            links: ["a/b.a"],
            dependencies: ["A 2", "B 1"]
        ),
        "B 3": Target.mock(
            product: .init(type: .uiTestBundle, name: "B3", path: "B3.xctest"),
            links: ["a/b.a"],
            dependencies: ["A 2", "B 1"]
        ),
        "C 1": Target.mock(
            product: .init(type: .staticLibrary, name: "c", path: "a/c.a"),
            srcs: ["a/b/c.m"]
        ),
        "E1": Target.mock(
            product: .init(type: .staticLibrary, name: "E1", path: "e1/E.a"),
            srcs: ["external/a_repo/a.swift"]
        ),
        "E2": Target.mock(
            product: .init(type: .staticLibrary, name: "E2", path: "e2/E.a"),
            srcs: ["external/another_repo/b.swift"]
        ),
    ]
    static func pbxProj() -> PBXProj {
        let pbxProj = PBXProj()

        let mainGroup = PBXGroup()
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
        internalDirectoryName: String = "rules_xcodeproj",
        workspaceOutputPath: Path = "some/Project.xcodeproj"
    ) -> [FilePath: PBXFileElement] {
        var elements: [FilePath: PBXFileElement] = [:]

        // external/a_repo/a.swift
        elements["external/a_repo/a.swift"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "a.swift"
        )
        elements["external/a_repo"] = PBXGroup(
            children: [elements["external/a_repo/a.swift"]!],
            sourceTree: .group,
            path: "a_repo"
        )

        // external/another_repo/b.swift
        elements["external/another_repo/b.swift"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.swift",
            path: "b.swift"
        )
        elements["external/another_repo"] = PBXGroup(
            children: [elements["external/another_repo/b.swift"]!],
            sourceTree: .group,
            path: "another_repo"
        )

        // external
        elements["external"] = PBXGroup(
            children: [
                elements["external/a_repo"]!,
                elements["external/another_repo"]!,
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

        // a/b/c.m
        elements["a/b/c.m"] = PBXFileReference(
            sourceTree: .group,
            lastKnownFileType: "sourcecode.c.objc",
            path: "c.m"
        )
        elements["a/b"] = PBXGroup(
            children: [elements["a/b/c.m"]!],
            sourceTree: .group,
            path: "b"
        )

        // Parent of the 4 above
        elements["a"] = PBXGroup(
            children: [
                // Folders are before files, then alphabetically
                elements["a/b"]!,
                elements["a/d"]!,
                elements["a/a.h"]!,
                elements["a/c.h"]!,
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
        elements[.internal("")] = PBXGroup(
            children: [elements[.internal("CompileStub.swift")]!],
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

        return elements
    }
}
