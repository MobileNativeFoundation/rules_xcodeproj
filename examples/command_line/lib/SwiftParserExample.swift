import Foundation
import SwiftSyntax
import SwiftSyntaxParser

@objcMembers
public class SwiftParserExample: NSObject {
    static let exampleSource = """
    let x = 2
    let y = 3_000
    """

    // public static func execute() -> String {
    public static var result: String {
        do {
            let sourceFile = try SyntaxParser.parse(source: Self.exampleSource)
            let incremented = AddOneToIntegerLiterals().visit(sourceFile)
            return "\(incremented)"

        } catch {
            return "ERROR OCCURRED: \(error)"
        }
    }
}

/// AddOneToIntegerLiterals will visit each token in the Syntax tree, and
/// (if it is an integer literal token) add 1 to the integer and return the
/// new integer literal token.
///
/// For example will it turn:
/// ```
/// let x = 2
/// let y = 3_000
/// ```
/// into:
/// ```
/// let x = 3
/// let y = 3001
/// ```
class AddOneToIntegerLiterals: SyntaxRewriter {
    override func visit(_ token: TokenSyntax) -> Syntax {
        // Only transform integer literals.
        guard case let .integerLiteral(text) = token.tokenKind else {
            return Syntax(token)
        }

        // Remove underscores from the original text.
        let integerText = String(text.filter { ("0" ... "9").contains($0) })

        // Parse out the integer.
        let int = Int(integerText)!

        // Create a new integer literal token with `int + 1` as its text.
        let newIntegerLiteralToken = token.withKind(.integerLiteral("\(int + 1)"))

        // Return the new integer literal.
        return Syntax(newIntegerLiteralToken)
    }
}
