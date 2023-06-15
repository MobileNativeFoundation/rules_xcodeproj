import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StringifyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self
    ]
}
