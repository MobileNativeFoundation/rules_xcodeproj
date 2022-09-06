import Foundation
import XCTest

// NOTE: This path has to start with a / for fileURLWithPath to resolve it correctly as an absolute path
public let kSourceRoot = ProcessInfo.processInfo.environment["SRCROOT"]!

private func remapFileURL(_ fileURL: URL) -> URL {
    if fileURL.path.hasPrefix(kSourceRoot) {
        return fileURL
    }

    return URL(fileURLWithPath: "\(kSourceRoot)/\(fileURL.relativePath)")
}

private extension XCTSourceCodeLocation {
    @objc
    convenience init(initWithRelativeFileURL relativeURL: URL, lineNumber: Int) {
        // NOTE: This call is not recursive because of swizzling
        self.init(initWithRelativeFileURL: remapFileURL(relativeURL), lineNumber: lineNumber)
    }
}

func swizzleXCTSourceCodeLocationIfNeeded() {
    // NOTE: Make sure our "Expand Variables Based On" is set correctly
    if kSourceRoot == "$(SRCROOT)" {
        fatalError("Got unsubstituted SRCROOT")
    }

    let originalSelector = #selector(XCTSourceCodeLocation.init(fileURL:lineNumber:))
    let swizzledSelector = #selector(XCTSourceCodeLocation.init(initWithRelativeFileURL:lineNumber:))

    guard let originalMethod = class_getInstanceMethod(XCTSourceCodeLocation.self, originalSelector),
        let swizzledMethod = class_getInstanceMethod(XCTSourceCodeLocation.self, swizzledSelector) else
    {
        fatalError("Failed to swizzle XCTSourceCodeLocation")
    }

    method_exchangeImplementations(originalMethod, swizzledMethod)
}
