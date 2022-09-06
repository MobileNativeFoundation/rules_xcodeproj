import Foundation
import PathKit
import XcodeProj

/// Wrapper for files (`PBXFileReference`, `PBXVariantGroup`, and
/// `XCVersionGroup`), adding additional associated data.
enum File: Equatable {
    case reference(PBXFileReference?, content: String?)
    case variantGroup(PBXVariantGroup)
    case xcVersionGroup(XCVersionGroup)
}

extension File {
    static func reference(_ reference: PBXFileReference) -> File {
        return .reference(reference, content: nil)
    }

    static func nonReferencedContent(_ content: String) -> File {
        return .reference(nil, content: content)
    }
}

extension File {
    var fileElement: PBXFileElement? {
        switch self {
        case let .reference(reference, _):
            return reference
        case let .variantGroup(group):
            return group
        case let .xcVersionGroup(group):
            return group
        }
    }
}

extension Generator {
    static let bazelForcedSwiftCompilePath: Path = "_BazelForcedCompile_.swift"
    static let compileStubPath: Path = "_CompileStub_.m"
    static let externalFileListPath: Path = "external.xcfilelist"
    static let appRsyncExcludeFileListPath: Path = "app.exclude.rsynclist"
    static let generatedFileListPath: Path = "generated.xcfilelist"
    static let createXcodeOverlayScriptPath: Path = "create_xcode_overlay.sh"
    static let lldbSwiftSettingsModulePath: Path = "swift_debug_settings.py"

    private static let localizedGroupExtensions: Set<String> = [
        "intentdefinition",
        "storyboard",
        "strings",
        "xib",
    ]

    enum ElementFilePath: Equatable, Hashable {
        case file(FilePath)
        case group(FilePath)

        var filePath: FilePath {
            switch self {
            case let .file(filePath): return filePath
            case let .group(filePath): return filePath
            }
        }
    }

    // Most of the logic here is a modified version of
    // https://github.com/tuist/tuist/blob/a76be1d1df2ec912cbf5c4ba91a167fb1dfd0098/Sources/TuistGenerator/Generator/ProjectFileElements.swift
    static func createFilesAndGroups(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        forceBazelDependencies: Bool,
        targets: [TargetID: Target],
        extraFiles: Set<FilePath>,
        xccurrentversions: [XCCurrentVersion],
        filePathResolver: FilePathResolver,
        logger: Logger
    ) throws -> (
        files: [FilePath: File],
        rootElements: [PBXFileElement],
        xcodeGeneratedFiles: Set<FilePath>,
        resolvedExternalRepositories: [(Path, Path)]
    ) {
        var fileReferences: [FilePath: PBXFileReference] = [:]
        var groups: [FilePath: PBXGroup] = [:]
        var knownRegions: Set<String> = []
        var resolvedExternalRepositories: [(Path, Path)] = []

        func resolveFilePath(
            _ filePath: FilePath,
            pathComponent: String,
            isGroup: Bool
        ) -> (
            sourceTree: PBXSourceTree,
            name: String?,
            path: String
        ) {
            if filePath.type == .external &&
                filePath.path.components.count <= 2,
               let symlinkDest = try? (
                filePathResolver.absoluteExternalDirectory + filePath.path
               ).symlinkDestination()
            {
                let workspaceDirectoryComponents = filePathResolver
                    .workspaceDirectoryComponents
                let symlinkComponents = symlinkDest.components
                if symlinkComponents.starts(
                    with: filePathResolver.workspaceDirectoryComponents
                ) {
                    let relativeComponents = symlinkComponents.suffix(
                        from: workspaceDirectoryComponents.count
                    )
                    let relativePath = Path(components: relativeComponents)

                    if isGroup {
                        resolvedExternalRepositories.append(
                            (filePath.path, "$(SRCROOT)" + relativePath)
                        )
                    }

                    return (
                        sourceTree: .sourceRoot,
                        name: pathComponent,
                        path: relativePath.string
                    )
                } else {
                    if isGroup {
                        resolvedExternalRepositories.append(
                            (filePath.path, symlinkDest)
                        )
                    }

                    return (
                        sourceTree: .absolute,
                        name: pathComponent,
                        path: symlinkDest.string
                    )
                }
            } else {
                return (
                    sourceTree: .group,
                    name: nil,
                    path: pathComponent
                )
            }
        }

        func createElement(
            in pbxProj: PBXProj,
            filePath: FilePath,
            pathComponent: String,
            isLeaf: Bool,
            forceGroupCreation: Bool
        ) -> (PBXFileElement, isNew: Bool)? {
            if filePath.path.isLocalizedContainer {
                // Localized container (e.g. /path/to/en.lproj)
                // We don't add it directly; an element will get added once the
                // next path component is evaluated.
                return nil
            } else if filePath.path.parent().isLocalizedContainer {
                // Localized file (e.g. /path/to/en.lproj/foo.png)
                if let group = groups[filePath] {
                    return (group, false)
                }
                return addLocalizedFile(filePath: filePath)
            } else if filePath.path.isCoreDataContainer {
                if let group = groups[filePath] {
                    return (group, false)
                }

                let (sourceTree, name, path) = resolveFilePath(
                    filePath,
                    pathComponent: pathComponent,
                    isGroup: true
                )

                let group = XCVersionGroup(
                    path: path,
                    name: name,
                    sourceTree: sourceTree,
                    versionGroupType: filePath.path.versionGroupType
                )
                pbxProj.add(object: group)

                groups[filePath] = group

                return (group, true)
            } else if !isLeaf, forceGroupCreation || !filePath.path.isFolderTypeFileSource {
                if let group = groups[filePath] {
                    return (group, false)
                }

                let group = createGroup(
                    filePath: filePath,
                    pathComponent: pathComponent
                )
                return (group, true)
            } else {
                if let fileReference = fileReferences[filePath] {
                    return (fileReference, false)
                }

                let (sourceTree, name, path) = resolveFilePath(
                    filePath,
                    pathComponent: pathComponent,
                    isGroup: false
                )

                let lastKnownFileType: String?
                if filePath.isFolder, !filePath.path.isFolderTypeFileSource {
                    lastKnownFileType = "folder"
                } else {
                    lastKnownFileType = filePath.path.lastKnownFileType
                }
                let file = PBXFileReference(
                    sourceTree: sourceTree,
                    name: name,
                    explicitFileType: filePath.path.explicitFileType,
                    lastKnownFileType: lastKnownFileType,
                    path: path
                )
                pbxProj.add(object: file)

                fileReferences[filePath] = file

                return (file, true)
            }
        }

        func createGroup(
            filePath: FilePath,
            pathComponent: String
        ) -> PBXGroup {
            let (sourceTree, name, path) = resolveFilePath(
                filePath,
                pathComponent: pathComponent,
                isGroup: true
            )

            let group = PBXGroup(
                sourceTree: sourceTree,
                name: name,
                path: path
            )
            pbxProj.add(object: group)
            groups[filePath] = group

            return group
        }

        func addLocalizedFile(
            filePath: FilePath
        ) -> (PBXVariantGroup, isNew: Bool) {
            // e.g. App.strings
            let fileName = filePath.path.lastComponent
            // e.g. resources/en.lproj
            let localizedContainerFilePath = filePath.parent()
            // e.g. resources/App.strings
            let groupFilePath = localizedContainerFilePath.parent() + fileName

            // TODO: Use `resolveFilePath`?

            // Variant group
            let group: PBXVariantGroup
            let isNew: Bool
            if let existingGroup = existingVariantGroup(containing: filePath) {
                isNew = false
                group = existingGroup.group
                // For variant groups formed by Interface Builder files (".xib"
                // or ".storyboard") and corresponding ".strings" files, name
                // and path of the group must have the extension of the
                // Interface Builder file. Since the order in which such groups
                // are formed is not deterministic, we must change the name and
                // path here as necessary.
                if ["xib", "storyboard"].contains(filePath.path.extension),
                   !group.name!.hasSuffix(fileName)
                {
                    group.name = fileName
                    groups[existingGroup.filePath] = nil
                    groups[groupFilePath] = group
                }
            } else {
                isNew = true
                group = PBXVariantGroup(
                    children: [],
                    sourceTree: .group,
                    name: fileName
                )
                pbxProj.add(object: group)
                groups[groupFilePath] = group
            }

            // Localized element
            let containedPath = Path(
                components: [
                    localizedContainerFilePath.path.lastComponent,
                    fileName,
                ]
            )
            let language = localizedContainerFilePath.path
                .lastComponentWithoutExtension

            let fileReference = PBXFileReference(
                sourceTree: .group,
                name: language,
                lastKnownFileType: filePath.path.lastKnownFileType,
                path: containedPath.string
            )
            pbxProj.add(object: fileReference)
            group.addChild(fileReference)

            // When a localized file is copied, we should grab the group instead
            groups[filePath] = group

            knownRegions.insert(language)

            return (group, isNew)
        }

        func existingVariantGroup(
            containing filePath: FilePath
        ) -> (group: PBXVariantGroup, filePath: FilePath)? {
            let groupBaseFilePath = filePath.parent().parent()

            // Variant groups used to localize Interface Builder or Intent
            // Definition files (".xib", ".storyboard", or ".intentdefition")
            // can contain files of these, respectively, and corresponding
            // ".strings" files. However, the groups' names must always use the
            // extension of the main file, i.e. either ".xib" or ".storyboard".
            // Since the order in which such groups are formed is not
            // deterministic, we must check for existing groups having the same
            // name as the localized file and any of these extensions.
            if let fileExtension = filePath.path.extension,
               Self.localizedGroupExtensions.contains(fileExtension)
            {
                for groupExtension in Self.localizedGroupExtensions {
                    let groupFilePath = groupBaseFilePath + """
\(filePath.path.lastComponentWithoutExtension).\(groupExtension)
"""
                    if let group = groups[groupFilePath] as? PBXVariantGroup {
                        return (group, groupFilePath)
                    }
                }
            }

            let groupFilePath = groupBaseFilePath + filePath.path.lastComponent
            guard let group = groups[groupFilePath] as? PBXVariantGroup else {
                return nil
            }

            return (group, groupFilePath)
        }

        var externalGroup: PBXGroup?
        func createExternalGroup() -> PBXGroup {
            if let externalGroup = externalGroup {
                return externalGroup
            }

            let group = PBXGroup(
                sourceTree: filePathResolver.externalDirectory.sourceTree,
                name: "Bazel External Repositories",
                path: filePathResolver.externalDirectory.string
            )
            pbxProj.add(object: group)
            groups[.external("")] = group
            externalGroup = group

            return group
        }

        var generatedGroup: PBXGroup?
        func createGeneratedGroup() -> PBXGroup {
            if let generatedGroup = generatedGroup {
                return generatedGroup
            }

            let group = PBXGroup(
                sourceTree: filePathResolver.bazelOutDirectory.sourceTree,
                name: "Bazel Generated Files",
                path: filePathResolver.bazelOutDirectory.string
            )
            pbxProj.add(object: group)
            groups[.generated("")] = group
            generatedGroup = group

            return group
        }

        var internalGroup: PBXGroup?
        func createInternalGroup() -> PBXGroup {
            if let internalGroup = internalGroup {
                return internalGroup
            }

            let group = PBXGroup(
                sourceTree: .group,
                name: filePathResolver.internalDirectoryName,
                path: filePathResolver.internalDirectory.string
            )
            pbxProj.add(object: group)
            groups[.internal("")] = group
            internalGroup = group

            return group
        }

        func isSpecialGroup(_ element: PBXFileElement) -> Bool {
            return element == externalGroup
                || element == generatedGroup
                || element == internalGroup
        }

        // Collect all files
        var allInputPaths = extraFiles
        for target in targets.values {
            allInputPaths.formUnion(target.inputs.all)
            // We use .nonGenerated instead of .all because generated files will
            // be collected via product outputs, or `extraFiles`
            allInputPaths.formUnion(target.linkerInputs.nonGenerated)
            allInputPaths.formUnion(
                target.outputs.forcedBazelCompileFiles(buildMode: buildMode)
            )
            if !target.inputs.containsSources,
                target.product.type.hasCompilePhase
            {
                allInputPaths.insert(.internal(compileStubPath))
            }
        }

        var rootElements: [PBXFileElement] = []
        var nonDirectFolderLikeFilePaths: Set<FilePath> = []
        var nonIncludedFiles: Set<FilePath> = []
        for fullFilePath in allInputPaths {
            guard fullFilePath.includeInNavigator else {
                nonIncludedFiles.insert(fullFilePath)
                continue
            }

            var filePath: FilePath
            var lastElement: PBXFileElement?
            switch fullFilePath.type {
            case .project:
                filePath = .project(Path())
                lastElement = nil
            case .external:
                filePath = .external(Path())
                lastElement = createExternalGroup()
            case .generated:
                filePath = .generated(Path())
                lastElement = createGeneratedGroup()
            case .internal:
                filePath = .internal(Path())
                lastElement = createInternalGroup()
            }

            var coreDataContainer: XCVersionGroup?
            let components = fullFilePath.path.components
            for (offset, component) in components.enumerated() {
                filePath = filePath + component
                let isLeaf = offset == components.count - 1
                filePath.isFolder = isLeaf && fullFilePath.isFolder
                if
                    let (element, isNew) = createElement(
                        in: pbxProj,
                        filePath: filePath,
                        pathComponent: component,
                        isLeaf: isLeaf,
                        forceGroupCreation: fullFilePath.forceGroupCreation
                    )
                {
                    if isNew {
                        if let group = lastElement as? PBXGroup {
                            // This will be the case for all non-root elements
                            group.addChild(element)
                        } else if !isSpecialGroup(element) {
                            rootElements.append(element)
                        }

                        if let coreDataContainer = coreDataContainer {
                            // When a model file is copied, we should grab
                            // the group instead
                            groups[filePath] = coreDataContainer
                        }
                    }

                    if let element = element as? XCVersionGroup {
                        coreDataContainer = element
                    }

                    lastElement = element

                    // End early if we get back a file element. This can happen
                    // if a folder-like file is added.
                    if element is PBXFileReference { break }
                }
            }

            if let coreDataContainer = coreDataContainer {
                // When a model file is copied, we should grab
                // the group instead
                groups[fullFilePath] = coreDataContainer
            } else if fullFilePath != filePath {
                // We need to add extra entries for file-like folders, to allow
                // easy copying of resources
                guard let reference = lastElement as? PBXFileReference else {
                    throw PreconditionError(message: """
`lastElement` wasn't a `PBXFileReference`
""")
                }
                fileReferences[fullFilePath] = reference
                nonDirectFolderLikeFilePaths.insert(filePath)
            }
        }

        // Fix sourceTree of `bazelForcedSwiftCompilePath` and `compileStubPath`
        if let element = fileReferences[.internal(bazelForcedSwiftCompilePath)] {
            element.sourceTree = .custom("DERIVED_FILE_DIR")
        }
        if let element = fileReferences[.internal(compileStubPath)] {
            element.sourceTree = .custom("DERIVED_FILE_DIR")
        }

        try setXCCurrentVersions(
            groups: groups,
            xccurrentversions: xccurrentversions,
            logger: logger
        )

        var files: [FilePath: File] = [:]
        for (filePath, fileReference) in fileReferences {
            files[filePath] = .reference(fileReference)
        }
        for (filePath, group) in groups {
            if let variantGroup = group as? PBXVariantGroup {
                files[filePath] = .variantGroup(variantGroup)
            } else if let xcVersionGroup = group as? XCVersionGroup {
                files[filePath] = .xcVersionGroup(xcVersionGroup)
            }
        }

        // Write xcfilelists

        let fileListFileFilePaths = fileReferences
            .filter { filePath, _ in
                return !nonDirectFolderLikeFilePaths.contains(filePath)
            }
            .map { filePath, _ in filePath }

        let externalPaths = try fileListFileFilePaths
            .filter { $0.type == .external }
            .map { try filePathResolver.resolve($0) }

        let generatedFilePaths = fileListFileFilePaths
            .filter { $0.type == .generated && !$0.isFolder } + nonIncludedFiles

        let generatedPaths = try generatedFilePaths.map { filePath in
            return try filePathResolver.resolve(filePath, useBazelOut: true)
        }

        if buildMode.usesBazelModeBuildScripts,
            targets.contains(where: { $1.product.type.isApplication })
        {
            files[.internal(appRsyncExcludeFileListPath)] =
                .nonReferencedContent(#"""
/*.app/Frameworks/libXCTestBundleInject.dylib
/*.app/Frameworks/libXCTestSwiftSupport.dylib
/*.app/Frameworks/XCTAutomationSupport.framework
/*.app/Frameworks/XCTest.framework
/*.app/Frameworks/XCTestCore.framework
/*.app/Frameworks/XCUIAutomation.framework
/*.app/Frameworks/XCUnit.framework
/*.app/PlugIns
/*.app/Watch

"""#)
        }

        func addXCFileList(_ path: Path, paths: [Path]) {
            guard !paths.isEmpty else {
                return
            }

            files[.internal(path)] = .nonReferencedContent(
                Set(paths.map { "\($0)\n" }).sortedLocalizedStandard().joined()
            )
        }

        addXCFileList(externalFileListPath, paths: externalPaths)
        addXCFileList(generatedFileListPath, paths: generatedPaths)

        // Write target internal files

        let hasBazelDependencies = needsBazelDependenciesTarget(
            buildMode: buildMode,
            forceBazelDependencies: forceBazelDependencies,
            files: files,
            hasTargets: !targets.isEmpty
        )

        // - `xcode-overlay.yaml`

        if hasBazelDependencies && buildMode == .xcode {
            let roots = try targets.values
                .compactMap { $0.outputs.swift?.generatedHeader }
                .map { filepath -> String in
                    let bazelOut = try filePathResolver.resolve(
                        filepath,
                        useBazelOut: true,
                        mode: .script
                    )
                    let buildDir = try filePathResolver.resolve(
                        filepath,
                        useBazelOut: false,
                        mode: .script
                    )
                    return #"""
{"external-contents": "\#(buildDir)","name": "${bazel_out_prefix}\#(bazelOut)","type": "file"}
"""#
                }
                .joined(separator: ",")

            files[.internal(createXcodeOverlayScriptPath)] =
                .nonReferencedContent(#"""
#!/bin/bash

# Look up Swift generated headers in `$BUILD_DIR` first, then fall through to
# `$BAZEL_OUT`
# `${bazel_out_prefix}` comes from sourcing script
cat > "$OBJROOT/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [\#(roots)],"version": 0}
EOF

"""#)
        }

        // - `lldbSwiftSettingsModule`

        var xcodeGeneratedFiles: Set<FilePath> = []
        switch buildMode {
        case .xcode:
            for (_, target) in targets {
                guard !target.isUnfocusedDependency else {
                    continue
                }

                xcodeGeneratedFiles.insert(target.product.path)
                if let filePath = target.outputs.swift?.module {
                    xcodeGeneratedFiles.insert(filePath)
                }
            }
        default:
            break
        }

        var lldbSettingsMap: [String: LLDBSettings] = [:]
        for target in targets.values {
            let linkopts = try target
                .allLinkerFlags(
                    xcodeGeneratedFiles: xcodeGeneratedFiles,
                    filePathResolver: filePathResolver
                )
                .map { "\($0)\n" }
            if !linkopts.isEmpty {
                files[try target.linkParamsFilePath()] =
                    .nonReferencedContent(linkopts.joined())
            }

            if let lldbContext = target.lldbContext {
                // Since `testonly` is viral, we only need to check the target
                let testingFrameworks: [String]
                let testingIncludes: [String]
                if target.isTestonly {
                    testingFrameworks = [
                        "$(PLATFORM_DIR)/Developer/Library/Frameworks",
                        // This one is set by Bazel, but not Xcode
                        "$(SDKROOT)/Developer/Library/Frameworks",
                    ]
                    testingIncludes = [
                        "$(PLATFORM_DIR)/Developer/usr/lib",
                    ]
                } else {
                    testingFrameworks = []
                    testingIncludes = []
                }

                let frameworks = try lldbContext.frameworkSearchPaths
                    .map { filePath -> String in
                        return try filePathResolver
                            .resolve(
                                filePath,
                                useBazelOut: true,
                                forceAbsoluteProjectPath: true
                            )
                            .string
                    }

                let includes = try lldbContext.swiftmodules
                    .map { filePath -> String in
                        var dir = filePath
                        dir.path = dir.path.parent().normalize()
                        return try filePathResolver
                            .resolve(
                                dir,
                                useBazelOut:
                                    !xcodeGeneratedFiles.contains(filePath),
                                forceAbsoluteProjectPath: true
                            )
                            .string
                    }
                    .uniqued()

                var onceFilePaths: Set<FilePath> = []
                var onceOtherFlags: Set<String> = []
                let clangOtherArgs = try lldbContext.clang.map { clang in
                    return try clang.toClangExtraArgs(
                        buildMode: buildMode,
                        hasBazelDependencies: hasBazelDependencies,
                        filePathResolver: filePathResolver,
                        onceFilePaths: &onceFilePaths,
                        onceOtherFlags: &onceOtherFlags
                    )
                }

                let clang = clangOtherArgs.joined(separator: " ")

                lldbSettingsMap[target.lldbSettingsKey] = LLDBSettings(
                    frameworks: testingFrameworks + frameworks,
                    includes: testingIncludes + includes,
                    clang: clang
                )
            }
        }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        jsonEncoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes,
        ]
        let lldbSettingsMapJSON = String(
            data: try jsonEncoder.encode(lldbSettingsMap),
            encoding: .utf8
        )!

        let lldbSwiftSettingsModule = #"""
#!/usr/bin/python3

"""An lldb module that registers a stop hook to set swift settings."""

import lldb

_BUNDLE_EXTENSIONS = [
    ".app",
    ".appex",
    ".bundle",
    ".framework",
    ".xctest",
]

_SETTINGS = \#(lldbSettingsMapJSON)

def __lldb_init_module(debugger, _internal_dict):
    # Register the stop hook when this module is loaded in lldb
    ci = debugger.GetCommandInterpreter()
    res = lldb.SBCommandReturnObject()
    ci.HandleCommand(
        "target stop-hook add -P swift_debug_settings.StopHook",
        res,
    )
    if not res.Succeeded():
        print(f"""\
Failed to register Swift debug options stop hook:

{res.GetError()}
Please file a bug report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
""")
        return

def _get_relative_executable_path(module):
    for extension in _BUNDLE_EXTENSIONS:
        prefix, _, suffix = module.rpartition(extension)
        if prefix:
            return prefix.split("/")[-1] + extension + suffix
    return module.split("/")[-1]

class StopHook:
    "An lldb stop hook class, that sets swift settings for the current module."

    def __init__(self, _target, _extra_args, _internal_dict):
        pass

    def handle_stop(self, exe_ctx, _stream):
        "Method that is called when the user stops in lldb."
        module = exe_ctx.frame.module
        module_name = module.file.__get_fullpath__()
        target_triple = module.GetTriple()
        executable_path = _get_relative_executable_path(module_name)
        key = f"{target_triple} {executable_path}"

        settings = _SETTINGS.get(key)

        if settings:
            frameworks = " ".join([
                f'"{path}"'
                for path in settings["frameworks"]
            ])
            if frameworks:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-framework-search-paths {frameworks}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-framework-search-paths",
                )

            includes = " ".join([
                f'"{path}"'
                for path in settings["includes"]
            ])
            if includes:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-module-search-paths {includes}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-module-search-paths",
                )

            clang = settings["clang"]
            if clang:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-extra-clang-flags '{clang}'",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-extra-clang-flags",
                )

        return True

"""#

        files[.internal(lldbSwiftSettingsModulePath)] =
            .nonReferencedContent(lldbSwiftSettingsModule)

        // Handle special groups

        rootElements.sortGroupedLocalizedStandard()
        if let externalGroup = externalGroup {
            externalGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(externalGroup)
        }
        if let generatedGroup = generatedGroup {
            generatedGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(generatedGroup)
        }
        if let internalGroup = internalGroup {
            internalGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(internalGroup)
        }

        // TODO: Configure development region?
        knownRegions.insert("en")

        // Xcode puts "Base" last after sorting
        knownRegions.remove("Base")
        pbxProj.rootObject!.knownRegions = knownRegions.sorted() + ["Base"]

        return (
            files,
            rootElements,
            xcodeGeneratedFiles,
            resolvedExternalRepositories
        )
    }

    private static func setXCCurrentVersions(
        groups: [FilePath: PBXGroup],
        xccurrentversions: [XCCurrentVersion],
        logger: Logger
    ) throws {
        for xccurrentversion in xccurrentversions {
            guard let group = groups[xccurrentversion.container] else {
                throw PreconditionError(message: """
"\(xccurrentversion.container.path)" `XCVersionGroup` not found in `elements`
""")
            }

            guard let container = group as? XCVersionGroup else {
                throw PreconditionError(message: """
"\(xccurrentversion.container.path)" isn't an `XCVersionGroup`
""")
            }

            guard
                let versionChild = container.children
                    .first(where: { $0.path == xccurrentversion.version })
            else {
                logger.logWarning("""
"\(xccurrentversion.container.path)" doesn't have \
"\(xccurrentversion.version)" as a child; not setting `currentVersion`
""")
                continue
            }

            guard let versionFile = versionChild as? PBXFileReference else {
                throw PreconditionError(message: """
"\(versionChild.path!)" is not a `PBXFileReference`
""")
            }

            container.currentVersion = versionFile
        }
    }
}

// MARK: - Private Types

private struct LLDBSettings: Equatable, Encodable {
    let frameworks: [String]
    let includes: [String]
    let clang: String
}

// MARK: - Extensions

private extension Target {
    private func lldbSettingsKey(baseKey: String) -> String {
        guard product.type.isBundle else {
            return baseKey
        }

        let executableName = product.executableName ??
            product.path.path.lastComponentWithoutExtension

        if platform.os == .macOS {
            return "\(baseKey)/Contents/MacOS/\(executableName)"
        } else {
            return "\(baseKey)/\(executableName)"
        }
    }

    var lldbSettingsKey: String {
        let baseKey = """
\(platform.targetTriple) \(product.path.path.lastComponent)
"""
        return lldbSettingsKey(baseKey: baseKey)
    }
}

private extension LLDBContext.Clang {
    private static let overlayFlags = #"""
-ivfsoverlay $(OBJROOT)/xcode-overlay.yaml \#
-ivfsoverlay $(OBJROOT)/bazel-out-overlay.yaml
"""#

    func toClangExtraArgs(
        buildMode: BuildMode,
        hasBazelDependencies: Bool,
        filePathResolver: FilePathResolver,
        onceFilePaths: inout Set<FilePath>,
        onceOtherFlags: inout Set<String>
    ) throws -> String {
        let quoteIncludesArgs: [String] = try quoteIncludes.map { filePath in
            let path = try filePathResolver
                .resolve(
                    filePath,
                    useBazelOut: true,
                    forceAbsoluteProjectPath: true
                )
                .string
            return #"-iquote "\#(path)""#
        }

        var includesArgs: [String] = []
        for filePath in includes {
            guard !onceFilePaths.contains(filePath) else {
                continue
            }
            onceFilePaths.insert(filePath)

            let path = try filePathResolver
                .resolve(
                    filePath,
                    useBazelOut: true,
                    forceAbsoluteProjectPath: true
                )
                .string
            includesArgs.append(#"-I "\#(path)""#)
        }

        let systemIncludesArgs: [String] = try systemIncludes.map { filePath in
            let path = try filePathResolver
                .resolve(
                    filePath,
                    useBazelOut: true,
                    forceAbsoluteProjectPath: true
                )
                .string
            return #"-isystem "\#(path)""#
        }

        let overlayArgs: [String]
        if hasBazelDependencies &&
            buildMode == .xcode &&
            !modulemaps.isEmpty &&
            !onceOtherFlags.contains(Self.overlayFlags)
            {
            onceOtherFlags.insert(Self.overlayFlags)
            overlayArgs = [Self.overlayFlags]
        } else {
            overlayArgs = []
        }

        var modulemapArgs: [String] = []
        for filePath in modulemaps {
            guard !onceFilePaths.contains(filePath) else {
                continue
            }
            onceFilePaths.insert(filePath)

            let modulemap = try filePathResolver
                .resolve(
                    filePath,
                    useBazelOut: true,
                    forceAbsoluteProjectPath: true
                )
                .string
            modulemapArgs.append(#"-fmodule-map-file="\#(modulemap)""#)
        }

        var filteredOpts: [String] = []
        for opt in opts {
            guard !onceOtherFlags.contains(opt) else {
                continue
            }
            // This can lead to correctness issues if the value of a define
            // is specified multiple times, and different on different targets,
            // but it's how lldb currently handles it. Ideally it should use
            // a dictionary for the key of the define and only filter ones that
            // have the same value as the last time the key was used.
            if opt.starts(with: "-D") {
                onceOtherFlags.insert(opt)
            }
            filteredOpts.append(opt)
        }

        return (
            overlayArgs +
            quoteIncludesArgs +
            includesArgs +
            systemIncludesArgs +
            modulemapArgs +
            filteredOpts
        )
            .joined(separator: " ")
    }
}

private extension Inputs {
    var containsSources: Bool { !srcs.isEmpty || !nonArcSrcs.isEmpty }
}

private extension Outputs {
    func forcedBazelCompileFiles(buildMode: BuildMode) -> Set<FilePath> {
        // TODO: Re-enable for Swift diagnostics replay
//        if buildMode.usesBazelModeBuildScripts, swift != nil {
//            return [.internal(Generator.bazelForcedSwiftCompilePath)]
//        }

        return []
    }
}

private extension Path {
    var sourceTree: PBXSourceTree { isAbsolute ? .absolute : .group }
}
