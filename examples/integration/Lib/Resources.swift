import Foundation

public let libResourcesString = "Hello, from Lib!"

private class ResourceHandle {}

public extension Bundle {
    static let libResources = Bundle(for: ResourceHandle.self)
}
