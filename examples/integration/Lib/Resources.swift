import Foundation

public let libResourcesString = "Hello, from Lib!"

private class ResourceHandle {}

extension Bundle {
    public static let libResources = Bundle(for: ResourceHandle.self)
}
