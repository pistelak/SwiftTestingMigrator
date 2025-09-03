import SwiftSyntax
import SwiftSyntaxBuilder

/// Shared utility for converting XCTest assertions to Swift Testing expectations
enum XCTestAssertionConverter {
    static func convertXCTestAssertion(_ node: FunctionCallExprSyntax, functionName: String) -> FunctionCallExprSyntax? {
        switch functionName {
        case "XCTAssertEqual":
            return convertXCTAssertEqual(node)
        case "XCTAssertTrue":
            return convertXCTAssertTrue(node)
        case "XCTAssertFalse":
            return convertXCTAssertFalse(node)
        case "XCTAssertNil":
            return convertXCTAssertNil(node)
        case "XCTAssertNotNil":
            return convertXCTAssertNotNil(node)
        case "XCTAssertThrowsError":
            return convertXCTAssertThrowsError(node)
        case "XCTFail":
            return convertXCTFail(node)
        default:
            return nil
        }
    }

    static func convertXCTAssertEqual(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard node.arguments.count >= 2,
              let firstArg = node.arguments.first,
              let secondArg = node.arguments.dropFirst().first else {
            return node
        }

        let equalityExpr = InfixOperatorExprSyntax(
            leftOperand: firstArg.expression,
            operator: BinaryOperatorExprSyntax(operator: .binaryOperator("==", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
            rightOperand: secondArg.expression
        )

        return createExpectCall(with: ExprSyntax(equalityExpr))
    }

    static func convertXCTAssertTrue(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        convertXCTAssertBoolean(node, expected: true)
    }

    static func convertXCTAssertFalse(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        convertXCTAssertBoolean(node, expected: false)
    }

    static func convertXCTAssertNil(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard let firstArg = node.arguments.first else { return node }

        let nilComparison = ExprSyntax(InfixOperatorExprSyntax(
            leftOperand: firstArg.expression,
            operator: BinaryOperatorExprSyntax(operator: .binaryOperator("==", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
            rightOperand: NilLiteralExprSyntax()
        ))

        return createExpectCall(with: nilComparison)
    }

    static func convertXCTAssertNotNil(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard let firstArg = node.arguments.first else { return node }

        let notNilComparison = ExprSyntax(InfixOperatorExprSyntax(
            leftOperand: firstArg.expression,
            operator: BinaryOperatorExprSyntax(operator: .binaryOperator("!=", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
            rightOperand: NilLiteralExprSyntax()
        ))

        return createExpectCall(with: notNilComparison)
    }

    static func convertXCTAssertThrowsError(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard let firstArg = node.arguments.first else { return node }

        return FunctionCallExprSyntax(
            calledExpression: MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier("expect")
            ) {},
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(
                    label: .identifier("throws"),
                    colon: .colonToken(trailingTrivia: [.spaces(1)]),
                    expression: ExprSyntax("(any Error).self")
                )
            ]),
            rightParen: .rightParenToken(),
            trailingClosure: ClosureExprSyntax(
                leftBrace: .leftBraceToken(leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)]),
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(item: .expr(firstArg.expression), trailingTrivia: [.spaces(1)])
                ]),
                rightBrace: .rightBraceToken()
            )
        )
    }

    static func convertXCTFail(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        return FunctionCallExprSyntax(
            calledExpression: MemberAccessExprSyntax(
                base: DeclReferenceExprSyntax(baseName: .identifier("Issue")),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier("record"))
            ),
            leftParen: .leftParenToken(),
            arguments: node.arguments,
            rightParen: .rightParenToken()
        )
    }

    /// Converts XCTAssertTrue/False into a #expect comparison
    private static func convertXCTAssertBoolean(_ node: FunctionCallExprSyntax, expected: Bool) -> FunctionCallExprSyntax {
        guard let firstArg = node.arguments.first else { return node }

        let finalExpression: ExprSyntax
        if needsExplicitBooleanComparison(firstArg.expression) {
            // Simple boolean property - add explicit comparison
            finalExpression = ExprSyntax(InfixOperatorExprSyntax(
                leftOperand: firstArg.expression,
                operator: BinaryOperatorExprSyntax(operator: .binaryOperator("==", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
                rightOperand: BooleanLiteralExprSyntax(literal: .keyword(expected ? .true : .false))
            ))
        } else {
            // Complex expression - use as-is
            finalExpression = firstArg.expression
        }

        return createExpectCall(with: finalExpression)
    }

    /// Determines if an expression needs explicit boolean comparison for boolean assertions
    /// Returns true for simple identifiers/member access, false for complex expressions
    private static func needsExplicitBooleanComparison(_ expression: ExprSyntax) -> Bool {
        // For XCTAssertTrue and XCTAssertFalse:
        // Simple cases that need explicit comparison with a boolean literal:
        // - Identifiers: `isValid`
        // - Member access: `user.isActive`, `items.isEmpty`
        // - Function calls: `isEnabled()`, `getValue()`

        // Complex cases that don't need explicit comparison (use as-is):
        // - Already have comparison operators: `value > 5`, `count == 0`
        // - Logical operators: `a && b`, `!condition`
        // - Other binary operators: `x + y`, `a - b`

        if expression.is(InfixOperatorExprSyntax.self) {
            // Already has an operator - don't add explicit comparison
            return false
        }

        if expression.is(PrefixOperatorExprSyntax.self) {
            // Already has a prefix operator (like !) - don't add explicit comparison
            return false
        }

        // Check the string representation for operators (fallback for when AST structure isn't precise)
        let exprString = expression.description.trimmingCharacters(in: .whitespaces)

        // If it contains operators, it's likely a complex expression
        let operators = [">", "<", ">=", "<=", "==", "!=", "&&", "||", "+", "-", "*", "/", "%", "!"]
        for operatorSymbol in operators {
            if exprString.contains(" \(operatorSymbol) ") || exprString.hasPrefix("\(operatorSymbol) ") {
                return false // Complex expression - don't add explicit comparison
            }
        }

        // Simple expressions need explicit comparison
        return true
    }

    /// Helper to create #expect(expression) - cleaner than building each time
    private static func createExpectCall(with expression: ExprSyntax) -> FunctionCallExprSyntax {
        return FunctionCallExprSyntax(
            calledExpression: MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier("expect")
            ) {},
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(expression: expression)
            ]),
            rightParen: .rightParenToken()
        )
    }
}
