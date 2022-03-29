import PathKit
import XcodeProj

extension Path {
    var isFolderTypeFileSource: Bool {
        return isXCAssets
            || isFramework
            || isBundle
            || isDocCArchive
            || isSceneKitAssets
    }

    var isLocalizedContainer: Bool { self.extension == "lproj" }

    var lastKnownFileType: String? {
        return self.extension.flatMap { Xcode.filetype(extension: $0) }
    }

    private var isDocCArchive: Bool { self.extension == "docc" }
    private var isBundle: Bool { self.extension == "bundle" }
    private var isFramework: Bool {
        return self.extension == "framework"
            || self.extension == "xcframework"
    }
    private var isSceneKitAssets: Bool { self.extension == "scnassets" }
    private var isXCAssets: Bool { self.extension == "xcassets" }
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
