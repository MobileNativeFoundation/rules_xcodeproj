import Foundation

@objc
public protocol FileManagerProtocol {
  @objc(contentsAtPath:)
  func contents(atPath path: String) -> Data?
}