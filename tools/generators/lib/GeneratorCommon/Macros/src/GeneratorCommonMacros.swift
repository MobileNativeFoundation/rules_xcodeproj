import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct GeneratorCommonMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self
    ]
}
