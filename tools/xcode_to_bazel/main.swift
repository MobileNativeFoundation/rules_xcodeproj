import Foundation
import PathKit
import ToolCommon
import XcodeProj

let logger = DefaultLogger(
    standardError: StderrOutputStream(),
    standardOutput: StdoutOutputStream(),
    colorize: false
)

do {
    guard CommandLine.arguments.count > 2 else {
        throw UsageError(message: "Usage: xcode_to_bazel <path to workspace> <relative path to xcodeproj>")
    }

    let workingDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
    let xcodeProj = try XcodeProj(
        path: Path(workingDirectory.path) + CommandLine.arguments[2]
    )

    // FIXME: Traverse folders referenced in Xcode to find ones with `Package.swift` at the root. Read `package.name` and `package.products` (maybe with `swift package dump-package`?). Add to `[String: String]`, mapping product name to local swift package name. This can be referenced when parsing `packageProductDependencies` to resolve "local" dependencies correctly.
    let localSwiftPackages = [
        "MastodonSDK": "MastodonSDK",
        "MastodonSDKDynamic": "MastodonSDK",
    ]

    let bazelPackages = try xcodeTargetsToBazelPackages(
        xcodeProj.pbxproj.nativeTargets,
        localSwiftPackages: localSwiftPackages
    )

    FileManager.default.changeCurrentDirectoryPath(workingDirectory.path)

    // FIXME: Determine if packages already exists and bail if non-compatible targets already exist (e.g. different rule type)
    let existingTargets: Set<Label> = []
    let existingBazelDeps: Set<String> = []

    // FIXME: Use above "package already exists" to augment this
    var pathsToCreate = bazelPackages.map { $0.path + "BUILD" }
    pathsToCreate.append("MODULE.bazel")
    try pathsToCreate.forEach { try "".writeCreatingParentDirectories(to: $0.url) }

    var buildozerCommands = buildozerCommandsForBazelPackages(
        bazelPackages,
        existingTargets: existingTargets,
        existingBazelDeps: existingBazelDeps
    )
    buildozerCommands.append("")
    let commandsContent = buildozerCommands.joined(separator: "\n")

    try commandsContent.writeCreatingParentDirectories(
        to: URL(fileURLWithPath: "/tmp/buildozer_cmds")
    )

    // FIXME: do this proper
    try #"""
// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcodeToBazel",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
    ],
    dependencies: [
        .package(name: "ArkanaKeys", path: "Dependencies/ArkanaKeys"),
        .package(name: "ArkanaKeysInterfaces", path: "Dependencies/ArkanaKeysInterfaces"),
        .package(name: "MastodonSDK", path: "MastodonSDK"),
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.2.7"),
        .package(url: "https://github.com/jdg/MBProgressHUD.git", from: "1.2.0"),
        .package(url: "https://github.com/Bearologics/LightChart.git", branch: "master"),
    ]
)

"""#.writeCreatingParentDirectories(to: URL(fileURLWithPath: "Package.swift"))

    try #"""
common --override_module=rules_swift_package_manager=/Users/brentley/Developer/rules_swift_package_manager
common --override_module=rules_swift=/Users/brentley/Developer/rules_swift

common --override_module=rules_xcodeproj=/Users/brentley/Developer/rules_xcodeproj

"""#.writeCreatingParentDirectories(to: URL(fileURLWithPath: ".bazelrc"))

    try "7.0.1\n".writeCreatingParentDirectories(to: URL(fileURLWithPath: ".bazelversion"))

    try #"""
{
  "direct_dep_identities": [
    "arkanakeys",
    "arkanakeysinterfaces",
    "kanna",
    "lightchart",
    "mastodonsdk",
    "mbprogresshud"
  ],
  "modules": [
    {
      "name": "Alamofire",
      "c99name": "Alamofire",
      "src_type": "swift",
      "label": "@swiftpkg_alamofire//:Alamofire.rspm",
      "package_identity": "alamofire",
      "product_memberships": [
        "Alamofire"
      ]
    },
    {
      "name": "AlamofireImage",
      "c99name": "AlamofireImage",
      "src_type": "swift",
      "label": "@swiftpkg_alamofireimage//:AlamofireImage.rspm",
      "modulemap_label": "@swiftpkg_alamofireimage//:AlamofireImage.rspm_modulemap",
      "package_identity": "alamofireimage",
      "product_memberships": [
        "AlamofireImage"
      ]
    },
    {
      "name": "ArkanaKeys",
      "c99name": "ArkanaKeys",
      "src_type": "swift",
      "label": "@swiftpkg_arkanakeys//:ArkanaKeys.rspm",
      "package_identity": "arkanakeys",
      "product_memberships": [
        "ArkanaKeys"
      ]
    },
    {
      "name": "ArkanaKeysInterfaces",
      "c99name": "ArkanaKeysInterfaces",
      "src_type": "swift",
      "label": "@swiftpkg_arkanakeysinterfaces//:ArkanaKeysInterfaces.rspm",
      "package_identity": "arkanakeysinterfaces",
      "product_memberships": [
        "ArkanaKeysInterfaces"
      ]
    },
    {
      "name": "FaviconFinder",
      "c99name": "FaviconFinder",
      "src_type": "swift",
      "label": "@swiftpkg_faviconfinder//:FaviconFinder.rspm",
      "package_identity": "faviconfinder",
      "product_memberships": [
        "FaviconFinder"
      ]
    },
    {
      "name": "FLAnimatedImage",
      "c99name": "FLAnimatedImage",
      "src_type": "objc",
      "label": "@swiftpkg_flanimatedimage//:FLAnimatedImage.rspm",
      "package_identity": "flanimatedimage",
      "product_memberships": [
        "FLAnimatedImage"
      ]
    },
    {
      "name": "Fuzi",
      "c99name": "Fuzi",
      "src_type": "swift",
      "label": "@swiftpkg_fuzi//:Fuzi.rspm",
      "package_identity": "fuzi",
      "product_memberships": [
        "Fuzi"
      ]
    },
    {
      "name": "FXPageControl",
      "c99name": "FXPageControl",
      "src_type": "objc",
      "label": "@swiftpkg_fxpagecontrol//:FXPageControl.rspm",
      "package_identity": "fxpagecontrol",
      "product_memberships": [
        "FXPageControl"
      ]
    },
    {
      "name": "Kanna",
      "c99name": "Kanna",
      "src_type": "swift",
      "label": "@swiftpkg_kanna//:Kanna.rspm",
      "package_identity": "kanna",
      "product_memberships": [
        "Kanna"
      ]
    },
    {
      "name": "KeychainAccess",
      "c99name": "KeychainAccess",
      "src_type": "swift",
      "label": "@swiftpkg_keychainaccess//:KeychainAccess.rspm",
      "package_identity": "keychainaccess",
      "product_memberships": [
        "KeychainAccess"
      ]
    },
    {
      "name": "LightChart",
      "c99name": "LightChart",
      "src_type": "swift",
      "label": "@swiftpkg_lightchart//:LightChart.rspm",
      "package_identity": "lightchart",
      "product_memberships": [
        "LightChart"
      ]
    },
    {
      "name": "CoreDataStack",
      "c99name": "CoreDataStack",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:CoreDataStack.rspm",
      "modulemap_label": "@swiftpkg_mastodonsdk//:CoreDataStack.rspm_modulemap",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonAsset",
      "c99name": "MastodonAsset",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonAsset.rspm",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonCommon",
      "c99name": "MastodonCommon",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonCommon.rspm",
      "modulemap_label": "@swiftpkg_mastodonsdk//:MastodonCommon.rspm_modulemap",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonCore",
      "c99name": "MastodonCore",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonCore.rspm",
      "modulemap_label": "@swiftpkg_mastodonsdk//:MastodonCore.rspm_modulemap",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonExtension",
      "c99name": "MastodonExtension",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonExtension.rspm",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonLocalization",
      "c99name": "MastodonLocalization",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonLocalization.rspm",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonSDK",
      "c99name": "MastodonSDK",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonSDK.rspm",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MastodonUI",
      "c99name": "MastodonUI",
      "src_type": "swift",
      "label": "@swiftpkg_mastodonsdk//:MastodonUI.rspm",
      "modulemap_label": "@swiftpkg_mastodonsdk//:MastodonUI.rspm_modulemap",
      "package_identity": "mastodonsdk",
      "product_memberships": [
        "MastodonSDK",
        "MastodonSDKDynamic"
      ]
    },
    {
      "name": "MBProgressHUD",
      "c99name": "MBProgressHUD",
      "src_type": "objc",
      "label": "@swiftpkg_mbprogresshud//:MBProgressHUD.rspm",
      "package_identity": "mbprogresshud",
      "product_memberships": [
        "MBProgressHUD"
      ]
    },
    {
      "name": "MastodonMeta",
      "c99name": "MastodonMeta",
      "src_type": "swift",
      "label": "@swiftpkg_metatextkit//:MastodonMeta.rspm",
      "package_identity": "metatextkit",
      "product_memberships": [
        "MetaTextKit"
      ]
    },
    {
      "name": "Meta",
      "c99name": "Meta",
      "src_type": "swift",
      "label": "@swiftpkg_metatextkit//:Meta.rspm",
      "package_identity": "metatextkit",
      "product_memberships": [
        "MetaTextKit"
      ]
    },
    {
      "name": "MetaTextKit",
      "c99name": "MetaTextKit",
      "src_type": "swift",
      "label": "@swiftpkg_metatextkit//:MetaTextKit.rspm",
      "modulemap_label": "@swiftpkg_metatextkit//:MetaTextKit.rspm_modulemap",
      "package_identity": "metatextkit",
      "product_memberships": [
        "MetaTextKit"
      ]
    },
    {
      "name": "TwitterMeta",
      "c99name": "TwitterMeta",
      "src_type": "swift",
      "label": "@swiftpkg_metatextkit//:TwitterMeta.rspm",
      "package_identity": "metatextkit",
      "product_memberships": [
        "MetaTextKit"
      ]
    },
    {
      "name": "SessionExporter",
      "c99name": "SessionExporter",
      "src_type": "swift",
      "label": "@swiftpkg_nextlevelsessionexporter//:SessionExporter.rspm",
      "package_identity": "nextlevelsessionexporter",
      "product_memberships": [
        "NextLevelSessionExporter"
      ]
    },
    {
      "name": "Nuke",
      "c99name": "Nuke",
      "src_type": "swift",
      "label": "@swiftpkg_nuke//:Nuke.rspm",
      "modulemap_label": "@swiftpkg_nuke//:Nuke.rspm_modulemap",
      "package_identity": "nuke",
      "product_memberships": [
        "Nuke"
      ]
    },
    {
      "name": "Pageboy",
      "c99name": "Pageboy",
      "src_type": "swift",
      "label": "@swiftpkg_pageboy//:Pageboy.rspm",
      "modulemap_label": "@swiftpkg_pageboy//:Pageboy.rspm_modulemap",
      "package_identity": "pageboy",
      "product_memberships": [
        "Pageboy"
      ]
    },
    {
      "name": "PanModal",
      "c99name": "PanModal",
      "src_type": "swift",
      "label": "@swiftpkg_panmodal//:PanModal.rspm",
      "modulemap_label": "@swiftpkg_panmodal//:PanModal.rspm_modulemap",
      "package_identity": "panmodal",
      "product_memberships": [
        "PanModal"
      ]
    },
    {
      "name": "SDWebImage",
      "c99name": "SDWebImage",
      "src_type": "objc",
      "label": "@swiftpkg_sdwebimage//:SDWebImage.rspm",
      "package_identity": "sdwebimage",
      "product_memberships": [
        "SDWebImage",
        "SDWebImageMapKit"
      ]
    },
    {
      "name": "SDWebImageMapKit",
      "c99name": "SDWebImageMapKit",
      "src_type": "objc",
      "label": "@swiftpkg_sdwebimage//:SDWebImageMapKit.rspm",
      "package_identity": "sdwebimage",
      "product_memberships": [
        "SDWebImageMapKit"
      ]
    },
    {
      "name": "Stripes",
      "c99name": "Stripes",
      "src_type": "swift",
      "label": "@swiftpkg_stripes//:Stripes.rspm",
      "package_identity": "stripes",
      "product_memberships": [
        "Stripes"
      ]
    },
    {
      "name": "Atomics",
      "c99name": "Atomics",
      "src_type": "swift",
      "label": "@swiftpkg_swift_atomics//:Atomics.rspm",
      "package_identity": "swift-atomics",
      "product_memberships": [
        "Atomics"
      ]
    },
    {
      "name": "_AtomicsShims",
      "c99name": "_AtomicsShims",
      "src_type": "clang",
      "label": "@swiftpkg_swift_atomics//:_AtomicsShims.rspm",
      "package_identity": "swift-atomics",
      "product_memberships": [
        "Atomics"
      ]
    },
    {
      "name": "Collections",
      "c99name": "Collections",
      "src_type": "swift",
      "label": "@swiftpkg_swift_collections//:Collections.rspm",
      "package_identity": "swift-collections",
      "product_memberships": [
        "Collections"
      ]
    },
    {
      "name": "DequeModule",
      "c99name": "DequeModule",
      "src_type": "swift",
      "label": "@swiftpkg_swift_collections//:DequeModule.rspm",
      "package_identity": "swift-collections",
      "product_memberships": [
        "Collections",
        "DequeModule"
      ]
    },
    {
      "name": "OrderedCollections",
      "c99name": "OrderedCollections",
      "src_type": "swift",
      "label": "@swiftpkg_swift_collections//:OrderedCollections.rspm",
      "package_identity": "swift-collections",
      "product_memberships": [
        "Collections",
        "OrderedCollections"
      ]
    },
    {
      "name": "CNIOAtomics",
      "c99name": "CNIOAtomics",
      "src_type": "clang",
      "label": "@swiftpkg_swift_nio//:CNIOAtomics.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOConcurrencyHelpers",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "CNIODarwin",
      "c99name": "CNIODarwin",
      "src_type": "clang",
      "label": "@swiftpkg_swift_nio//:CNIODarwin.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "CNIOLLHTTP",
      "c99name": "CNIOLLHTTP",
      "src_type": "clang",
      "label": "@swiftpkg_swift_nio//:CNIOLLHTTP.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOHTTP1",
        "NIOWebSocket",
        "NIOTestUtils"
      ]
    },
    {
      "name": "CNIOLinux",
      "c99name": "CNIOLinux",
      "src_type": "clang",
      "label": "@swiftpkg_swift_nio//:CNIOLinux.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "CNIOSHA1",
      "c99name": "CNIOSHA1",
      "src_type": "clang",
      "label": "@swiftpkg_swift_nio//:CNIOSHA1.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOWebSocket"
      ]
    },
    {
      "name": "CNIOWindows",
      "c99name": "CNIOWindows",
      "src_type": "clang",
      "label": "@swiftpkg_swift_nio//:CNIOWindows.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "NIO",
      "c99name": "NIO",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIO.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIO",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils"
      ]
    },
    {
      "name": "NIOConcurrencyHelpers",
      "c99name": "NIOConcurrencyHelpers",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOConcurrencyHelpers.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOConcurrencyHelpers",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "NIOCore",
      "c99name": "NIOCore",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOCore.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "NIOEmbedded",
      "c99name": "NIOEmbedded",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOEmbedded.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIO",
        "NIOEmbedded",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils"
      ]
    },
    {
      "name": "NIOFileSystem",
      "c99name": "NIOFileSystem",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOFileSystem.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "NIOFileSystemFoundationCompat",
      "c99name": "NIOFileSystemFoundationCompat",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOFileSystemFoundationCompat.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "NIOFoundationCompat",
      "c99name": "NIOFoundationCompat",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOFoundationCompat.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOFoundationCompat"
      ]
    },
    {
      "name": "NIOHTTP1",
      "c99name": "NIOHTTP1",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOHTTP1.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOHTTP1",
        "NIOWebSocket",
        "NIOTestUtils"
      ]
    },
    {
      "name": "NIOPosix",
      "c99name": "NIOPosix",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOPosix.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIO",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils"
      ]
    },
    {
      "name": "NIOTLS",
      "c99name": "NIOTLS",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOTLS.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOTLS"
      ]
    },
    {
      "name": "NIOTestUtils",
      "c99name": "NIOTestUtils",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOTestUtils.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOTestUtils"
      ]
    },
    {
      "name": "NIOWebSocket",
      "c99name": "NIOWebSocket",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:NIOWebSocket.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOWebSocket"
      ]
    },
    {
      "name": "_NIOBase64",
      "c99name": "_NIOBase64",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:_NIOBase64.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "_NIOConcurrency",
      "c99name": "_NIOConcurrency",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:_NIOConcurrency.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "_NIOConcurrency"
      ]
    },
    {
      "name": "_NIODataStructures",
      "c99name": "_NIODataStructures",
      "src_type": "swift",
      "label": "@swiftpkg_swift_nio//:_NIODataStructures.rspm",
      "package_identity": "swift-nio",
      "product_memberships": [
        "NIOCore",
        "NIO",
        "NIOEmbedded",
        "NIOPosix",
        "_NIOConcurrency",
        "NIOTLS",
        "NIOHTTP1",
        "NIOFoundationCompat",
        "NIOWebSocket",
        "NIOTestUtils",
        "_NIOFileSystem",
        "_NIOFileSystemFoundationCompat"
      ]
    },
    {
      "name": "CSystem",
      "c99name": "CSystem",
      "src_type": "clang",
      "label": "@swiftpkg_swift_system//:CSystem.rspm",
      "package_identity": "swift-system",
      "product_memberships": [
        "SystemPackage"
      ]
    },
    {
      "name": "SystemPackage",
      "c99name": "SystemPackage",
      "src_type": "swift",
      "label": "@swiftpkg_swift_system//:SystemPackage.rspm",
      "package_identity": "swift-system",
      "product_memberships": [
        "SystemPackage"
      ]
    },
    {
      "name": "SwiftSoup",
      "c99name": "SwiftSoup",
      "src_type": "swift",
      "label": "@swiftpkg_swiftsoup//:SwiftSoup.rspm",
      "package_identity": "swiftsoup",
      "product_memberships": [
        "SwiftSoup"
      ]
    },
    {
      "name": "TabBarPager",
      "c99name": "TabBarPager",
      "src_type": "swift",
      "label": "@swiftpkg_tabbarpager//:TabBarPager.rspm",
      "package_identity": "tabbarpager",
      "product_memberships": [
        "TabBarPager"
      ]
    },
    {
      "name": "Tabman",
      "c99name": "Tabman",
      "src_type": "swift",
      "label": "@swiftpkg_tabman//:Tabman.rspm",
      "modulemap_label": "@swiftpkg_tabman//:Tabman.rspm_modulemap",
      "package_identity": "tabman",
      "product_memberships": [
        "Tabman"
      ]
    },
    {
      "name": "CropViewController",
      "c99name": "CropViewController",
      "src_type": "swift",
      "label": "@swiftpkg_tocropviewcontroller//:CropViewController.rspm",
      "modulemap_label": "@swiftpkg_tocropviewcontroller//:CropViewController.rspm_modulemap",
      "package_identity": "tocropviewcontroller",
      "product_memberships": [
        "CropViewController"
      ]
    },
    {
      "name": "TOCropViewController",
      "c99name": "TOCropViewController",
      "src_type": "objc",
      "label": "@swiftpkg_tocropviewcontroller//:TOCropViewController.rspm",
      "package_identity": "tocropviewcontroller",
      "product_memberships": [
        "TOCropViewController",
        "CropViewController"
      ]
    },
    {
      "name": "UIHostingConfigurationBackport",
      "c99name": "UIHostingConfigurationBackport",
      "src_type": "swift",
      "label": "@swiftpkg_uihostingconfigurationbackport//:UIHostingConfigurationBackport.rspm",
      "package_identity": "uihostingconfigurationbackport",
      "product_memberships": [
        "UIHostingConfigurationBackport"
      ]
    },
    {
      "name": "UITextView+Placeholder",
      "c99name": "UITextView_Placeholder",
      "src_type": "objc",
      "label": "@swiftpkg_uitextview_placeholder//:UITextView+Placeholder.rspm",
      "package_identity": "uitextview-placeholder",
      "product_memberships": [
        "UITextView+Placeholder"
      ]
    },
    {
      "name": "XLPagerTabStrip",
      "c99name": "XLPagerTabStrip",
      "src_type": "swift",
      "label": "@swiftpkg_xlpagertabstrip//:XLPagerTabStrip.rspm",
      "modulemap_label": "@swiftpkg_xlpagertabstrip//:XLPagerTabStrip.rspm_modulemap",
      "package_identity": "xlpagertabstrip",
      "product_memberships": [
        "XLPagerTabStrip"
      ]
    }
  ],
  "products": [
    {
      "identity": "alamofireimage",
      "name": "AlamofireImage",
      "type": "library",
      "label": "@swiftpkg_alamofireimage//:AlamofireImage"
    },
    {
      "identity": "alamofire",
      "name": "Alamofire",
      "type": "library",
      "label": "@swiftpkg_alamofire//:Alamofire"
    },
    {
      "identity": "arkanakeysinterfaces",
      "name": "ArkanaKeysInterfaces",
      "type": "library",
      "label": "@swiftpkg_arkanakeysinterfaces//:ArkanaKeysInterfaces"
    },
    {
      "identity": "arkanakeys",
      "name": "ArkanaKeys",
      "type": "library",
      "label": "@swiftpkg_arkanakeys//:ArkanaKeys"
    },
    {
      "identity": "faviconfinder",
      "name": "FaviconFinder",
      "type": "library",
      "label": "@swiftpkg_faviconfinder//:FaviconFinder"
    },
    {
      "identity": "flanimatedimage",
      "name": "FLAnimatedImage",
      "type": "library",
      "label": "@swiftpkg_flanimatedimage//:FLAnimatedImage"
    },
    {
      "identity": "fuzi",
      "name": "Fuzi",
      "type": "library",
      "label": "@swiftpkg_fuzi//:Fuzi"
    },
    {
      "identity": "fxpagecontrol",
      "name": "FXPageControl",
      "type": "library",
      "label": "@swiftpkg_fxpagecontrol//:FXPageControl"
    },
    {
      "identity": "kanna",
      "name": "Kanna",
      "type": "library",
      "label": "@swiftpkg_kanna//:Kanna"
    },
    {
      "identity": "keychainaccess",
      "name": "KeychainAccess",
      "type": "library",
      "label": "@swiftpkg_keychainaccess//:KeychainAccess"
    },
    {
      "identity": "lightchart",
      "name": "LightChart",
      "type": "library",
      "label": "@swiftpkg_lightchart//:LightChart"
    },
    {
      "identity": "mastodonsdk",
      "name": "MastodonSDK",
      "type": "library",
      "label": "@swiftpkg_mastodonsdk//:MastodonSDK"
    },
    {
      "identity": "mastodonsdk",
      "name": "MastodonSDKDynamic",
      "type": "library",
      "label": "@swiftpkg_mastodonsdk//:MastodonSDKDynamic"
    },
    {
      "identity": "mbprogresshud",
      "name": "MBProgressHUD",
      "type": "library",
      "label": "@swiftpkg_mbprogresshud//:MBProgressHUD"
    },
    {
      "identity": "metatextkit",
      "name": "MetaTextKit",
      "type": "library",
      "label": "@swiftpkg_metatextkit//:MetaTextKit"
    },
    {
      "identity": "nextlevelsessionexporter",
      "name": "NextLevelSessionExporter",
      "type": "library",
      "label": "@swiftpkg_nextlevelsessionexporter//:NextLevelSessionExporter"
    },
    {
      "identity": "nuke",
      "name": "Nuke",
      "type": "library",
      "label": "@swiftpkg_nuke//:Nuke"
    },
    {
      "identity": "pageboy",
      "name": "Pageboy",
      "type": "library",
      "label": "@swiftpkg_pageboy//:Pageboy"
    },
    {
      "identity": "panmodal",
      "name": "PanModal",
      "type": "library",
      "label": "@swiftpkg_panmodal//:PanModal"
    },
    {
      "identity": "sdwebimage",
      "name": "SDWebImage",
      "type": "library",
      "label": "@swiftpkg_sdwebimage//:SDWebImage"
    },
    {
      "identity": "sdwebimage",
      "name": "SDWebImageMapKit",
      "type": "library",
      "label": "@swiftpkg_sdwebimage//:SDWebImageMapKit"
    },
    {
      "identity": "stripes",
      "name": "Stripes",
      "type": "library",
      "label": "@swiftpkg_stripes//:Stripes"
    },
    {
      "identity": "swift-atomics",
      "name": "Atomics",
      "type": "library",
      "label": "@swiftpkg_swift_atomics//:Atomics"
    },
    {
      "identity": "swift-collections",
      "name": "Collections",
      "type": "library",
      "label": "@swiftpkg_swift_collections//:Collections"
    },
    {
      "identity": "swift-collections",
      "name": "DequeModule",
      "type": "library",
      "label": "@swiftpkg_swift_collections//:DequeModule"
    },
    {
      "identity": "swift-collections",
      "name": "OrderedCollections",
      "type": "library",
      "label": "@swiftpkg_swift_collections//:OrderedCollections"
    },
    {
      "identity": "swift-nio",
      "name": "NIO",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIO"
    },
    {
      "identity": "swift-nio",
      "name": "NIOConcurrencyHelpers",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOConcurrencyHelpers"
    },
    {
      "identity": "swift-nio",
      "name": "NIOCore",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOCore"
    },
    {
      "identity": "swift-nio",
      "name": "NIOEmbedded",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOEmbedded"
    },
    {
      "identity": "swift-nio",
      "name": "NIOFoundationCompat",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOFoundationCompat"
    },
    {
      "identity": "swift-nio",
      "name": "NIOHTTP1",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOHTTP1"
    },
    {
      "identity": "swift-nio",
      "name": "NIOPosix",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOPosix"
    },
    {
      "identity": "swift-nio",
      "name": "NIOTLS",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOTLS"
    },
    {
      "identity": "swift-nio",
      "name": "NIOTestUtils",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOTestUtils"
    },
    {
      "identity": "swift-nio",
      "name": "NIOWebSocket",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:NIOWebSocket"
    },
    {
      "identity": "swift-nio",
      "name": "_NIOConcurrency",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:_NIOConcurrency"
    },
    {
      "identity": "swift-nio",
      "name": "_NIOFileSystem",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:_NIOFileSystem"
    },
    {
      "identity": "swift-nio",
      "name": "_NIOFileSystemFoundationCompat",
      "type": "library",
      "label": "@swiftpkg_swift_nio//:_NIOFileSystemFoundationCompat"
    },
    {
      "identity": "swift-system",
      "name": "SystemPackage",
      "type": "library",
      "label": "@swiftpkg_swift_system//:SystemPackage"
    },
    {
      "identity": "swiftsoup",
      "name": "SwiftSoup",
      "type": "library",
      "label": "@swiftpkg_swiftsoup//:SwiftSoup"
    },
    {
      "identity": "tabbarpager",
      "name": "TabBarPager",
      "type": "library",
      "label": "@swiftpkg_tabbarpager//:TabBarPager"
    },
    {
      "identity": "tabman",
      "name": "Tabman",
      "type": "library",
      "label": "@swiftpkg_tabman//:Tabman"
    },
    {
      "identity": "tocropviewcontroller",
      "name": "CropViewController",
      "type": "library",
      "label": "@swiftpkg_tocropviewcontroller//:CropViewController"
    },
    {
      "identity": "tocropviewcontroller",
      "name": "TOCropViewController",
      "type": "library",
      "label": "@swiftpkg_tocropviewcontroller//:TOCropViewController"
    },
    {
      "identity": "uihostingconfigurationbackport",
      "name": "UIHostingConfigurationBackport",
      "type": "library",
      "label": "@swiftpkg_uihostingconfigurationbackport//:UIHostingConfigurationBackport"
    },
    {
      "identity": "uitextview-placeholder",
      "name": "UITextView+Placeholder",
      "type": "library",
      "label": "@swiftpkg_uitextview_placeholder//:UITextView+Placeholder"
    },
    {
      "identity": "xlpagertabstrip",
      "name": "XLPagerTabStrip",
      "type": "library",
      "label": "@swiftpkg_xlpagertabstrip//:XLPagerTabStrip"
    }
  ],
  "packages": [
    {
      "name": "swiftpkg_alamofire",
      "identity": "alamofire",
      "remote": {
        "commit": "3dc6a42c7727c49bf26508e29b0a0b35f9c7e1ad",
        "remote": "https://github.com/Alamofire/Alamofire.git",
        "version": "5.8.1"
      }
    },
    {
      "name": "swiftpkg_alamofireimage",
      "identity": "alamofireimage",
      "remote": {
        "commit": "1eaf3b6c6882bed10f6e7b119665599dd2329aa1",
        "remote": "https://github.com/Alamofire/AlamofireImage.git",
        "version": "4.3.0"
      }
    },
    {
      "name": "swiftpkg_arkanakeys",
      "identity": "arkanakeys",
      "local": {
        "path": "Dependencies/ArkanaKeys"
      }
    },
    {
      "name": "swiftpkg_arkanakeysinterfaces",
      "identity": "arkanakeysinterfaces",
      "local": {
        "path": "Dependencies/ArkanaKeysInterfaces"
      }
    },
    {
      "name": "swiftpkg_faviconfinder",
      "identity": "faviconfinder",
      "remote": {
        "commit": "1f74844f77f79b95c0bb0130b3a87d4f340e6d3a",
        "remote": "https://github.com/will-lumley/FaviconFinder.git",
        "version": "3.3.0"
      }
    },
    {
      "name": "swiftpkg_flanimatedimage",
      "identity": "flanimatedimage",
      "remote": {
        "commit": "d4f07b6f164d53c1212c3e54d6460738b1981e9f",
        "remote": "https://github.com/Flipboard/FLAnimatedImage.git",
        "version": "1.0.17"
      }
    },
    {
      "name": "swiftpkg_fuzi",
      "identity": "fuzi",
      "remote": {
        "commit": "f08c8323da21e985f3772610753bcfc652c2103f",
        "remote": "https://github.com/cezheng/Fuzi.git",
        "version": "3.1.3"
      }
    },
    {
      "name": "swiftpkg_fxpagecontrol",
      "identity": "fxpagecontrol",
      "remote": {
        "commit": "a94633402ba98c52f86c2a70e61ff086dec9de78",
        "remote": "https://github.com/nicklockwood/FXPageControl.git",
        "version": "1.6.0"
      }
    },
    {
      "name": "swiftpkg_kanna",
      "identity": "kanna",
      "remote": {
        "commit": "f9e4922223dd0d3dfbf02ca70812cf5531fc0593",
        "remote": "https://github.com/tid-kijyun/Kanna.git",
        "version": "5.2.7"
      }
    },
    {
      "name": "swiftpkg_keychainaccess",
      "identity": "keychainaccess",
      "remote": {
        "commit": "84e546727d66f1adc5439debad16270d0fdd04e7",
        "remote": "https://github.com/kishikawakatsumi/KeychainAccess.git",
        "version": "4.2.2"
      }
    },
    {
      "name": "swiftpkg_lightchart",
      "identity": "lightchart",
      "remote": {
        "commit": "a7e724e9ec3cdcaa2d0840b95780e66b870dbf1e",
        "remote": "https://github.com/Bearologics/LightChart.git",
        "branch": "master"
      }
    },
    {
      "name": "swiftpkg_mastodonsdk",
      "identity": "mastodonsdk",
      "local": {
        "path": "MastodonSDK"
      }
    },
    {
      "name": "swiftpkg_mbprogresshud",
      "identity": "mbprogresshud",
      "remote": {
        "commit": "bca42b801100b2b3a4eda0ba8dd33d858c780b0d",
        "remote": "https://github.com/jdg/MBProgressHUD.git",
        "version": "1.2.0"
      }
    },
    {
      "name": "swiftpkg_metatextkit",
      "identity": "metatextkit",
      "remote": {
        "commit": "dcd5255d6930c2fab408dc8562c577547e477624",
        "remote": "https://github.com/TwidereProject/MetaTextKit.git",
        "version": "2.2.5"
      }
    },
    {
      "name": "swiftpkg_nextlevelsessionexporter",
      "identity": "nextlevelsessionexporter",
      "remote": {
        "commit": "b6c0cce1aa37fe1547d694f958fac3c3524b74da",
        "remote": "https://github.com/NextLevel/NextLevelSessionExporter.git",
        "version": "0.4.6"
      }
    },
    {
      "name": "swiftpkg_nuke",
      "identity": "nuke",
      "remote": {
        "commit": "a002b7fd786f2df2ed4333fe73a9727499fd9d97",
        "remote": "https://github.com/kean/Nuke.git",
        "version": "10.11.2"
      }
    },
    {
      "name": "swiftpkg_pageboy",
      "identity": "pageboy",
      "remote": {
        "commit": "af8fa81788b893205e1ff42ddd88c5b0b315d7c5",
        "remote": "https://github.com/uias/Pageboy",
        "version": "3.7.0"
      }
    },
    {
      "name": "swiftpkg_panmodal",
      "identity": "panmodal",
      "remote": {
        "commit": "b012aecb6b67a8e46369227f893c12544846613f",
        "remote": "https://github.com/slackhq/PanModal.git",
        "version": "1.2.7"
      }
    },
    {
      "name": "swiftpkg_sdwebimage",
      "identity": "sdwebimage",
      "remote": {
        "commit": "59730af512c06fb569c119d737df4c1c499e001d",
        "remote": "https://github.com/SDWebImage/SDWebImage.git",
        "version": "5.18.10"
      }
    },
    {
      "name": "swiftpkg_stripes",
      "identity": "stripes",
      "remote": {
        "commit": "d533fd44b8043a3abbf523e733599173d6f98c11",
        "remote": "https://github.com/eneko/Stripes.git",
        "version": "0.2.0"
      }
    },
    {
      "name": "swiftpkg_swift_atomics",
      "identity": "swift-atomics",
      "remote": {
        "commit": "cd142fd2f64be2100422d658e7411e39489da985",
        "remote": "https://github.com/apple/swift-atomics.git",
        "version": "1.2.0"
      }
    },
    {
      "name": "swiftpkg_swift_collections",
      "identity": "swift-collections",
      "remote": {
        "commit": "d029d9d39c87bed85b1c50adee7c41795261a192",
        "remote": "https://github.com/apple/swift-collections.git",
        "version": "1.0.6"
      }
    },
    {
      "name": "swiftpkg_swift_nio",
      "identity": "swift-nio",
      "remote": {
        "commit": "635b2589494c97e48c62514bc8b37ced762e0a62",
        "remote": "https://github.com/apple/swift-nio.git",
        "version": "2.63.0"
      }
    },
    {
      "name": "swiftpkg_swift_system",
      "identity": "swift-system",
      "remote": {
        "commit": "025bcb1165deab2e20d4eaba79967ce73013f496",
        "remote": "https://github.com/apple/swift-system.git",
        "version": "1.2.1"
      }
    },
    {
      "name": "swiftpkg_swiftsoup",
      "identity": "swiftsoup",
      "remote": {
        "commit": "f83c097597094a04124eb6e0d1e894d24129af87",
        "remote": "https://github.com/scinfu/SwiftSoup.git",
        "version": "2.7.0"
      }
    },
    {
      "name": "swiftpkg_tabbarpager",
      "identity": "tabbarpager",
      "remote": {
        "commit": "488aa66d157a648901b61721212c0dec23d27ee5",
        "remote": "https://github.com/TwidereProject/TabBarPager.git",
        "version": "0.1.0"
      }
    },
    {
      "name": "swiftpkg_tabman",
      "identity": "tabman",
      "remote": {
        "commit": "4a4f7c755b875ffd4f9ef10d67a67883669d2465",
        "remote": "https://github.com/uias/Tabman",
        "version": "2.13.0"
      }
    },
    {
      "name": "swiftpkg_tocropviewcontroller",
      "identity": "tocropviewcontroller",
      "remote": {
        "commit": "d0470491f56e734731bbf77991944c0dfdee3e0e",
        "remote": "https://github.com/TimOliver/TOCropViewController.git",
        "version": "2.6.1"
      }
    },
    {
      "name": "swiftpkg_uihostingconfigurationbackport",
      "identity": "uihostingconfigurationbackport",
      "remote": {
        "commit": "6091f2d38faa4b24fc2ca0389c651e2f666624a3",
        "remote": "https://github.com/woxtu/UIHostingConfigurationBackport.git",
        "version": "0.1.0"
      }
    },
    {
      "name": "swiftpkg_uitextview_placeholder",
      "identity": "uitextview-placeholder",
      "remote": {
        "commit": "20f513ded04a040cdf5467f0891849b1763ede3b",
        "remote": "https://github.com/MainasuK/UITextView-Placeholder.git",
        "version": "1.4.1"
      }
    },
    {
      "name": "swiftpkg_xlpagertabstrip",
      "identity": "xlpagertabstrip",
      "remote": {
        "commit": "211ed62aa376722cf93c429802a8b6ff66a8bd52",
        "remote": "https://github.com/xmartlabs/XLPagerTabStrip.git",
        "version": "9.1.0"
      }
    }
  ]
}

"""#.writeCreatingParentDirectories(to: URL(fileURLWithPath: "swift_deps_index.json"))

    let (_, buildozerStderr, buildozerExitCode) = try runSubProcess(
        currentDirectoryURL: workingDirectory,
        "/opt/homebrew/bin/buildozer",
        ["-f", "/tmp/buildozer_cmds", "-shorten_labels"]
    )
    if buildozerExitCode != 0 {
        throw UsageError(message: "Failed to apply buildozer:\n\(buildozerStderr.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    if !buildozerStderr.isEmpty {
        print(buildozerStderr.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var swiftPkgs: Set<String> = []
    var localSwiftPkgs: Set<String> = []
    for bazelPackage in bazelPackages {
        swiftPkgs.formUnion(bazelPackage.swiftPkgs)
        localSwiftPkgs.formUnion(bazelPackage.localSwiftPkgs)
    }

    // FIXME: Determine when we need this
    try #"""
# swift_deps START
swift_deps = use_extension(
    "@rules_swift_package_manager//:extensions.bzl",
    "swift_deps",
)
swift_deps.from_file(
    deps_index = "//:swift_deps_index.json",
)
use_repo(
    swift_deps,
    \#(swiftPkgs.sorted().map { $0.quoted }.joined(separator: ",\n    ")),
)
# swift_deps END

bazel_dep(
    name = "apple_support",
    version = "1.11.1",
    dev_dependency = True,
    repo_name = "build_bazel_apple_support",
)

"""#.append(to: URL(fileURLWithPath: "MODULE.bazel"))

    let (buildifierStdout, buildifierStderr, buildifierExitCode) = try runSubProcess(
        currentDirectoryURL: workingDirectory,
        "/opt/homebrew/bin/buildifier",
        ["--lint=fix", "--warnings=out-of-order-load,load-on-top", "-r", "."]
    )
    if buildifierExitCode != 0 {
        throw UsageError(message: "Failed to apply buildifier:\n\(buildifierStderr)")
    }
    if !buildifierStdout.isEmpty {
        print("buildifier output:")
        print(buildifierStdout.trimmingCharacters(in: .whitespacesAndNewlines))
    }
} catch {
    logger.logError(error.localizedDescription)
    exit(1)
}

extension String {
    func append(to url: URL) throws {
        let fileHandle = try FileHandle(forWritingTo: url)
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(Data(utf8))
    }
}
