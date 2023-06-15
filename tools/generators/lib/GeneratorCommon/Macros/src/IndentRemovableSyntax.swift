import SwiftSyntax

protocol IndentRemovableSyntax {
    var removingIndents: Self { get }
    mutating func removeIndents()
}

extension IndentRemovableSyntax {
    mutating func removeIndents() {
        self = removingIndents
    }
}

extension SyntaxProtocol where Self: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension SyntaxCollection where Element: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.removeIndents()

        return ret
    }

    mutating func removeIndents() {
        self = Self(
            map { $0.removingIndents }
        )
    }
}

extension FunctionParameterSyntax: IndentRemovableSyntax {}
extension TokenSyntax: IndentRemovableSyntax {}
extension TupleTypeElementSyntax: IndentRemovableSyntax {}

extension AvailabilityArgumentSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.entry.removeIndents()

        return ret
    }
}

extension AvailabilityArgumentSyntax.Entry: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .availabilityLabeledArgument(labeled):
            return .availabilityLabeledArgument(labeled.removingIndents)
        case let .availabilityVersionRestriction(version):
            return .availabilityVersionRestriction(version.removingIndents)
        case let .token(token):
            return .token(token.removingIndents)
        }
    }
}

extension AvailabilityConditionSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.availabilityKeyword.removeIndents()
        ret.availabilitySpec.removeIndents()
        ret.leftParen.removeIndents()
        ret.rightParen.removeIndents()

        return ret
    }
}

extension AvailabilityLabeledArgumentSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.label.removeIndents()
        ret.value.removeIndents()

        return ret
    }
}

extension AvailabilityLabeledArgumentSyntax.Value: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .string(string):
            return .string(string.removingIndents)
        case let .version(version):
            return .version(version.removingIndents)
        }
    }
}

extension AvailabilityVersionRestrictionSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.platform.removeIndents()
        ret.version?.removeIndents()

        return ret
    }
}

extension CaseItemSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.pattern.removeIndents()

        return ret
    }
}

extension CatchClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.catchKeyword.removeIndents()
        ret.catchItems?.removeIndents()
        ret.body.removeIndents()

        return ret
    }
}

extension CatchItemSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.pattern?.removeIndents()
        ret.whereClause?.removeIndents()

        return ret
    }
}

extension ClosureExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftBrace.removeIndents()
        ret.signature?.removeIndents()
        ret.statements.removeIndents()
        ret.rightBrace.removeIndents()

        return ret
    }
}

extension ClosureParameterClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftParen.removeIndents()
        ret.parameterList.removeIndents()
        ret.rightParen.removeIndents()

        return ret
    }
}

extension ClosureParameterSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
//        ret.attributes?.removeIndents()
//        ret.modifiers?.removeIndents()
        ret.firstName.removeIndents()
        ret.secondName?.removeIndents()
        ret.type?.removeIndents()

        return ret
    }
}

extension ClosureParamSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension ClosureSignatureSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.input?.removeIndents()
        ret.inTok.removeIndents()
        ret.output?.removeIndents()

        return ret
    }
}

extension ClosureSignatureSyntax.Input: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .simpleInput(paramList):
            return .simpleInput(paramList.removingIndents)
        case let .input(input):
            return .input(input.removingIndents)
        }
    }
}

extension CodeBlockSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftBrace.removeIndents()
        ret.statements.removeIndents()
        ret.rightBrace.removeIndents()

        return ret
    }
}

extension CodeBlockItemSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        let newItem: Item
        switch item {
        case let .decl(decl):
            newItem = .decl(.init(decl.removingIndents))
        case let .stmt(stmt):
            newItem = .stmt(stmt.removingIndents)
        case let .expr(expr):
            newItem = .expr(expr.removingIndents)
        }

        // `leadingTrivia` is purposefully removed
        return Self(
            item: newItem,
            semicolon: semicolon,
            trailingTrivia: trailingTrivia
        )
    }
}

extension ConditionElementSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.condition.removeIndents()

        return ret
    }
}

extension ConditionElementSyntax.Condition: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .availability(availability):
            return .availability(availability.removingIndents)
        case let .expression(expression):
            return .expression(expression.removingIndents)
        case let .matchingPattern(matchingPattern):
            return .matchingPattern(matchingPattern.removingIndents)
        case let .optionalBinding(optionalBinding):
            return .optionalBinding(optionalBinding.removingIndents)
        }
    }
}






extension MatchingPatternConditionSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.caseKeyword.removeIndents()
        ret.initializer.removeIndents()
        ret.pattern.removeIndents()
        ret.typeAnnotation?.removeIndents()

        return ret
    }
}

extension OptionalBindingConditionSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.bindingKeyword.removeIndents()
        ret.initializer?.removeIndents()
        ret.pattern.removeIndents()
        ret.typeAnnotation?.removeIndents()

        return ret
    }
}



extension DeclNameArgumentSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.colon.removeIndents()
        ret.name.removeIndents()

        return ret
    }
}

extension DeclNameArgumentsSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftParen.removeIndents()
        ret.arguments.removeIndents()
        ret.rightParen.removeIndents()

        return ret
    }
}

extension DeclSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        if let funcDecl = `as`(FunctionDeclSyntax.self) {
            return DeclSyntax(funcDecl.removingIndents)
        }
        if let variableDecl = `as`(VariableDeclSyntax.self) {
            return DeclSyntax(variableDecl.removingIndents)
        }

        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension DoStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.doKeyword.removeIndents()
        ret.body.removeIndents()
        ret.catchClauses?.removeIndents()

        return ret
    }
}

extension TryExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.tryKeyword.removeIndents()
        ret.questionOrExclamationMark?.removeIndents()
        ret.expression.removeIndents()

        return ret
    }
}

extension ExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        if let functionCall = `as`(FunctionCallExprSyntax.self) {
            return ExprSyntax(functionCall.removingIndents)
        }
        if let ifExpr = `as`(IfExprSyntax.self) {
            return ExprSyntax(ifExpr.removingIndents)
        }
        if let memberAccess = `as`(MemberAccessExprSyntax.self) {
            return ExprSyntax(memberAccess.removingIndents)
        }
        if let switchExpr = `as`(SwitchExprSyntax.self) {
            return ExprSyntax(switchExpr.removingIndents)
        }
        if let tryExpr = `as`(TryExprSyntax.self) {
            return ExprSyntax(tryExpr.removingIndents)
        }
        if let tuple = `as`(TupleExprSyntax.self) {
            return ExprSyntax(tuple.removingIndents)
        }

        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension ExpressionStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.expression.removeIndents()

        return ret
    }
}

extension ForInStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.forKeyword.removeIndents()
        ret.inKeyword.removeIndents()
        ret.sequenceExpr.removeIndents()
        ret.pattern.removeIndents()
        ret.body.removeIndents()
        ret.awaitKeyword?.removeIndents()
        ret.caseKeyword?.removeIndents()
        ret.tryKeyword?.removeIndents()
        ret.whereClause?.removeIndents()

        return ret
    }
}

extension FunctionCallExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.calledExpression.removeIndents()
        ret.leftParen?.removeIndents()
        ret.argumentList.removeIndents()
        ret.rightParen?.removeIndents()
        ret.trailingClosure?.removeIndents()

        return ret
    }
}

extension FunctionDeclSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.signature.removeIndents()
        ret.body?.removeIndents()

        return ret
    }
}

extension FunctionSignatureSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.input.removeIndents()
        ret.output?.removeIndents()

        return ret
    }
}

extension GenericRequirementSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.body.removeIndents()

        return ret
    }
}




extension ConformanceRequirementSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftTypeIdentifier.removeIndents()
        ret.colon.removeIndents()
        ret.rightTypeIdentifier.removeIndents()

        return ret
    }
}

extension LayoutRequirementSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.alignment?.removeIndents()
        ret.colon.removeIndents()
        ret.layoutConstraint.removeIndents()
        ret.leftParen?.removeIndents()
        ret.rightParen?.removeIndents()
        ret.size?.removeIndents()
        ret.typeIdentifier.removeIndents()

        return ret
    }
}

extension SameTypeRequirementSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftTypeIdentifier.removeIndents()
        ret.equalityToken.removeIndents()
        ret.rightTypeIdentifier.removeIndents()

        return ret
    }
}



extension GenericRequirementSyntax.Body: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .conformanceRequirement(conformanceReq):
            return .conformanceRequirement(conformanceReq.removingIndents)
        case let .layoutRequirement(layoutReq):
            return .layoutRequirement(layoutReq.removingIndents)
        case let .sameTypeRequirement(sameTypeReq):
            return .sameTypeRequirement(sameTypeReq.removingIndents)
        }
    }
}

extension GenericWhereClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.whereKeyword.removeIndents()
        ret.requirementList.removeIndents()

        return ret
    }
}

extension GuardStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.guardKeyword.removeIndents()
        ret.conditions.removeIndents()
        ret.elseKeyword.removeIndents()
        ret.body.removeIndents()

        return ret
    }
}

extension IfConfigDeclSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension IfExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.ifKeyword.removeIndents()
        ret.conditions.removeIndents()
        ret.body.removeIndents()
        ret.elseKeyword?.removeIndents()
        ret.elseBody?.removeIndents()

        return ret
    }
}

extension IfExprSyntax.ElseBody: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .ifExpr(ifExpr):
            return .ifExpr(ifExpr.removingIndents)
        case let .codeBlock(codeBlock):
            return .codeBlock(codeBlock.removingIndents)
        }
    }
}

extension InitializerClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.equal.removeIndents()
        ret.value.removeIndents()

        return ret
    }
}

extension MemberAccessExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.base?.removeIndents()
        ret.dot.removeIndents()
        ret.name.removeIndents()
        ret.declNameArguments?.removeIndents()

        return ret
    }
}

extension ParameterClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftParen.removeIndents()
        ret.parameterList.removeIndents()
        ret.rightParen.removeIndents()

        return ret
    }
}

extension PatternBindingSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.pattern.removeIndents()
        ret.initializer?.removeIndents()

        return ret
    }
}

extension PatternSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension ReturnClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.returnType.removeIndents()

        return ret
    }
}

extension ReturnStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.expression?.removeIndents()

        return ret
    }
}

extension StmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        if let doStmt = `as`(DoStmtSyntax.self) {
            return StmtSyntax(doStmt.removingIndents)
        }
        if let expressionStmt = `as`(ExpressionStmtSyntax.self) {
            return StmtSyntax(expressionStmt.removingIndents)
        }
        if let forInStmt = `as`(ForInStmtSyntax.self) {
            return StmtSyntax(forInStmt.removingIndents)
        }
        if let guardStmt = `as`(GuardStmtSyntax.self) {
            return StmtSyntax(guardStmt.removingIndents)
        }
        if let repeatWhileStmt = `as`(RepeatWhileStmtSyntax.self) {
            return StmtSyntax(repeatWhileStmt.removingIndents)
        }
        if let returnStmt = `as`(ReturnStmtSyntax.self) {
            return StmtSyntax(returnStmt.removingIndents)
        }
        if let throwStmt = `as`(ThrowStmtSyntax.self) {
            return StmtSyntax(throwStmt.removingIndents)
        }
        if let whileStmt = `as`(WhileStmtSyntax.self) {
            return StmtSyntax(whileStmt.removingIndents)
        }

        var ret = self

        ret.leadingTrivia.removeIndents()

        return ret
    }
}

extension RepeatWhileStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.repeatKeyword.removeIndents()
        ret.condition.removeIndents()
        ret.body.removeIndents()

        return ret
    }
}

extension StringLiteralExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        // TODO: Remove more from other parts?
        // Might be hard with multi-line strings

        return ret
    }
}

extension SwitchCaseListSyntax.Element: IndentRemovableSyntax {
    var removingIndents: Self {
        switch self {
        case let .switchCase(switchCase):
            return .switchCase(switchCase.removingIndents)
        case let .ifConfigDecl(ifConfig):
            return .ifConfigDecl(ifConfig.removingIndents)
        }
    }
}

extension SwitchCaseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
//        ret.label.removeIndents()
        ret.statements.removeIndents()

        return ret
    }
}

extension SwitchCaseLabelSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.caseKeyword.removeIndents()
        ret.caseItems.removeIndents()

        return ret
    }
}

extension SwitchExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftBrace.removeIndents()
        ret.expression.removeIndents()
        ret.cases.removeIndents()
        ret.rightBrace.removeIndents()

        return ret
    }
}

extension ThrowStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.throwKeyword.removeIndents()
        ret.expression.removeIndents()

        return ret
    }
}

extension TypeAnnotationSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.colon.removeIndents()
        ret.type.removeIndents()

        return ret
    }
}

extension TypeSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        if let tuple = `as`(TupleTypeSyntax.self) {
            return TypeSyntax(tuple.removingIndents)
        }

        return self
    }
}

extension TupleExprSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftParen.removeIndents()
        ret.elementList.removeIndents()
        ret.rightParen.removeIndents()

        return ret
    }
}

extension TupleExprElementSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.expression.removeIndents()

        return ret
    }
}

extension TupleTypeSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.leftParen.removeIndents()
        ret.elements.removeIndents()
        ret.rightParen.removeIndents()

        return ret
    }
}

extension WhereClauseSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.whereKeyword.removeIndents()
        ret.guardResult.removeIndents()

        return ret
    }
}

extension WhileStmtSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.whileKeyword.removeIndents()
        ret.conditions.removeIndents()
        ret.body.removeIndents()

        return ret
    }
}

extension VariableDeclSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.bindingKeyword.removeIndents()
        ret.bindings.removeIndents()

        return ret
    }
}

extension VersionTupleSyntax: IndentRemovableSyntax {
    var removingIndents: Self {
        var ret = self

        ret.leadingTrivia.removeIndents()
        ret.major.removeIndents()
        ret.minor?.removeIndents()
        ret.minorPeriod?.removeIndents()
        ret.patch?.removeIndents()
        ret.patchPeriod?.removeIndents()

        return ret
    }
}

// MARK: - Trivia

private extension Trivia {
    var removingIndents: Self {
        var ret = self

        ret.removeIndents()

        return ret
    }

    mutating func removeIndents() {
        self = Trivia(pieces: pieces.removingIndents)
    }
}

private extension Trivia {
    var decrementNewlines: Self {
        var ret = self

        ret.decrementingNewlines()

        return ret
    }

    mutating func decrementingNewlines() {
        self = Trivia(pieces: pieces.decrementNewlines)
    }
}

private extension Array where Element == TriviaPiece {
    var decrementNewlines: Self {
        return compactMap { piece in
            switch piece {
            case let .newlines(newlines):
                let newNewlines = newlines - 1
                guard newNewlines > 0 else {
                    return nil
                }
                return .newlines(newNewlines)
            default:
                return piece
            }
        }
    }
}

private extension Array where Element == TriviaPiece {
    var removingIndents: Self {
        return filter { piece in
            switch piece {
            case .spaces, .tabs: return false
            default: return true
            }
        }
    }
}
