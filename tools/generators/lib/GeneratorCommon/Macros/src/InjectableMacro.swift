import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum InjectableError: CustomStringConvertible, Error {
    case notAFunction
    case notASingleStatement

    var description: String {
        switch self {
        case .notAFunction: return "#Injectable must wrap a function"
        case .notASingleStatement: return "#Injectable must wrap a single function"
        }
    }
}

private let voidReturnClause = ReturnClauseSyntax(
    returnType: SimpleTypeIdentifierSyntax(name: .identifier("Void"))
)

public struct InjectableMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let closure = node.closureArgument else {
            fatalError("""
compiler bug: the macro does not have a closure as the first argument
""")
        }

        guard let statement = closure.statements.first,
            closure.statements.count == 1
        else {
            // FIXME: better diagnostics (line number)
            throw InjectableError.notASingleStatement
        }

        guard let function = statement.item
            .as(FunctionDeclSyntax.self)?.removingIndents
        else {
            // FIXME: better diagnostics (line number)
            throw InjectableError.notAFunction
        }

        let argInfos = function.signature.input.parameterList.map { arg in
            return (
                name: (arg.secondName ?? arg.firstName).text,
                type: arg.type
            )
        }

        let structName = function.identifier.text.capitalizedFirstLetter

        let rawFunctionCall = FunctionCallExprSyntax(
            callee: IdentifierExprSyntax(
                identifier: .identifier("callable")
            )
        ) {
            for arg in argInfos {
                TupleExprElementSyntax(
                    expression: IdentifierExprSyntax(
                        identifier: .identifier(arg.name)
                    )
                )
            }
        }

        let functionCall: ExprSyntax
        if function.signature.effectSpecifiers?.throwsSpecifier != nil {
            functionCall = ExprSyntax(
                TryExprSyntax(expression: rawFunctionCall)
            )
        } else {
            functionCall = ExprSyntax(rawFunctionCall)
        }

        let callableStruct = StructDeclSyntax(
            leadingTrivia: .init(pieces: [.newlines(2)]),
            identifier: .identifier(structName)
        ) {
            // typealias Callable = (_ bar: String, _ baz: Int) -> Bool
            TypealiasDeclSyntax(
                identifier: .identifier("Callable"),
                initializer: TypeInitializerClauseSyntax(
                    value: FunctionTypeSyntax(
                        arguments: TupleTypeElementListSyntax {
                            for arg in argInfos {
                                TupleTypeElementSyntax(
                                    name: "_",
                                    secondName: .identifier(arg.name),
                                    colon: .colonToken(),
                                    type: arg.type
                                )
                            }
                        },
                        effectSpecifiers: function.signature.effectSpecifiers
                            .map { x in .init(
                                asyncSpecifier: x.asyncSpecifier,
                                throwsSpecifier: x.throwsSpecifier
                            )},
                        output: function.signature.output ?? voidReturnClause
                    )
                )
            )

            // private let callable: Callable
            VariableDeclSyntax(
                leadingTrivia: .init(pieces: [.newlines(2)]),
                modifiers: .init([.init(name: .identifier("private"))]),
                .let,
                name: .init(
                    IdentifierPatternSyntax(identifier: .identifier("callable"))
                ),
                type: .init(
                    type: SimpleTypeIdentifierSyntax(
                        name: .identifier("Callable")
                    )
                )
            )

            // init(callable: @escaping Callable = foo) {}
            InitializerDeclSyntax(
                leadingTrivia: .init(pieces: [.newlines(2)]),
                signature: .init(
                    input: ParameterClauseSyntax {
                        FunctionParameterSyntax(
                            firstName: .identifier("callable"),
                            type: AttributedTypeSyntax(
                                specifier: .identifier("@escaping"),
                                baseType: SimpleTypeIdentifierSyntax(
                                    name: .identifier("Callable")
                                )
                            ),
                            defaultArgument: .init(
                                value: IdentifierExprSyntax(
                                    identifier: function.identifier
                                )
                            )
                        )
                    }
                )
            ) {
                ExprSyntax("self.callable = callable")
            }

            // func callAsFunction(bar: String, baz: Int) -> Bool {
            //     return callable(bar, baz)
            // }
            FunctionDeclSyntax(
                leadingTrivia: .init(
                    pieces: [.newlines(1)] + function.leadingTrivia.pieces
                ),
                identifier: .identifier("callAsFunction"),
                signature: function.signature
            ) {
                if function.signature.output != nil {
                    ReturnStmtSyntax(
                        expression: functionCall
                    )
                } else {
                    functionCall
                }
            }
        }

        let finalFunction: FunctionDeclSyntax
        if node.asStatic {
            finalFunction = function.asStatic
        } else {
            finalFunction = function
        }

        return [
            finalFunction.cast(DeclSyntax.self),
            callableStruct.cast(DeclSyntax.self),
        ]
    }
}

private extension FreestandingMacroExpansionSyntax {
    var closureArgument: ClosureExprSyntax? {
        if let closure = trailingClosure {
            return closure
        }

        return argumentList
            .first(where: { $0.label?.text == "wrappedFunction" })?
            .expression.cast(ClosureExprSyntax.self)
    }

    var asStatic: Bool {
        return argumentList
            .first(where: { $0.label?.text == "asStatic" })?
            .expression.cast(BooleanLiteralExprSyntax.self)
            .booleanLiteral.tokenKind == .keyword(.true)
    }
}

private extension FunctionDeclSyntax {
    var asStatic: Self {
        return FunctionDeclSyntax(
            leadingTrivia: leadingTrivia,
            modifiers: .init([.init(name: .keyword(.static))]),
            identifier: identifier,
            genericParameterClause: genericParameterClause,
            signature: signature,
            genericWhereClause: genericWhereClause,
            body: body,
            trailingTrivia: trailingTrivia
        )
    }
}

private extension String {
    var capitalizedFirstLetter: String {
        return self.prefix(1).localizedCapitalized + self.dropFirst()
    }
}
