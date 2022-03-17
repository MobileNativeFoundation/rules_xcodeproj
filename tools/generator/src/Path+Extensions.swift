import PathKit
import XcodeProj

extension Path {
    var isFolderTypeFileSource: Bool {
        return isXCAssets || isDocCArchive || isSceneKitAssets
    }

    var lastKnownFileType: String? {
        return self.extension.flatMap { Xcode.filetype(extension: $0) }
    }

    private var isDocCArchive: Bool { self.extension == "docc" }
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
