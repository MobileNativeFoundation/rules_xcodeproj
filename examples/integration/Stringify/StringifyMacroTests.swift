//import StringifyMacroPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

class StringifyMacroTests: XCTestCase {
    func test() {
        assertMacroExpansion(
            """
#stringify(a + b)
""",
            expandedSource: """
(a + b, "a + b")
""",
            macros: testMacros
        )
    }
}

private let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self
]
