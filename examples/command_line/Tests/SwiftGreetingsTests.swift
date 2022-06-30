import Foundation
@testable import LibSwift
import XCTest

class SwiftGreetingsTests: XCTestCase {

  func test_greeting() throws {
    XCTAssertEqual("SwiftyLibrary", SwiftGreetings.greeting())
  }
}
