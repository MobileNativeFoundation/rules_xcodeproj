import Foundation
@testable import LibSwift
import XCTest

class SwiftGreetingsTests: XCTestCase {

  func test_greeting() throws {
    XCTAssertEqual("Swifty", SwiftGreetings.greeting)
  }
}
