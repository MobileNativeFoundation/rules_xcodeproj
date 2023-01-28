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
        lastComponent == "BUILD" || lastComponent == "BUILD.bazel"
    }

    var explicitFileType: String? {
        isBazelBuildFile ? Xcode.filetype(extension: "py") : nil
    }

    var lastKnownFileType: String? {
        // XcodeProj treats `.inc` files as Pascal source files, but
        // they're commonly C/C++ headers, so map them as such here.
        if self.extension == "inc", let ext = Xcode.filetype(extension: "h") {
            return ext
        }
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
    private var isFramework: Bool { self.extension == "framework" }
    private var isSceneKitAssets: Bool { self.extension == "scnassets" }
    private var isXCAssets: Bool { self.extension == "xcassets" }
}

extension String {
    /// Wraps the path in quotes if it needs it.
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
