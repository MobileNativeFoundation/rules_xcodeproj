import Foundation
import XCTest

@testable import LibSwift

class SwiftGreetingsTests: XCTestCase {
  func test_greeting() throws {
    XCTAssertEqual("SneakySwiftyLibrarySwiftCModule", SwiftGreetings.greeting())
  }
}
