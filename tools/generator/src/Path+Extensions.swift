import PathKit
import XcodeProj

extension Path {
    var isFolderTypeFileSource: Bool {
        return isXCAssets
            || isFramework
            || isBundle
            || isDocCArchive
            || isSceneKitAssets
            || isCoreDataModel
    }

    var isCoreDataContainer: Bool { self.extension == "xcdatamodeld" }
    var isLocalizedContainer: Bool { self.extension == "lproj" }

    var isBazelBuildFile: Bool {
        self.lastComponent == "BUILD" || self.lastComponent == "BUILD.bazel"
    }

    var explicitFileType: String? {
        self.isBazelBuildFile ? Xcode.filetype(extension: "py") : nil
    }

    var lastKnownFileType: String? {
        return self.extension.flatMap { Xcode.filetype(extension: $0) }
    }

    var versionGroupType: String? {
        switch self.extension {
        case "xcdatamodeld":
            return "wrapper.xcdatamodel"
        case let fileExtension?:
            return Xcode.filetype(extension: fileExtension)
        default:
            return nil
        }
    }

    private var isBundle: Bool { self.extension == "bundle" }
    private var isCoreDataModel: Bool { self.extension == "xcdatamodel" }
    private var isDocCArchive: Bool { self.extension == "docc" }
    private var isFramework: Bool {
        return self.extension == "framework"
    }
    private var isSceneKitAssets: Bool { self.extension == "scnassets" }
    private var isXCAssets: Bool { self.extension == "xcassets" }
}

extension Path {
    mutating func replaceExtension(_ newExtension: String) {
        self = replacingExtension(newExtension)
    }

    func replacingExtension(_ newExtension: String) -> Path {
        if let `extension` = `extension` {
            return Path(string.dropLast(`extension`.count) + newExtension)
        } else {
            return Path("\(string).\(newExtension)")
        }
    }
}

extension String {
    /// Wraps the path in quotes if it needs it
    var quoted: String {
        guard rangeOfCharacter(from: .whitespaces) != nil else {
            return self
        }
        return #""\#(self)""#
    }
}

// MARK: Decodable

extension Path: RawRepresentable, Decodable {
    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public var rawValue: String {
        return string
    }
}
