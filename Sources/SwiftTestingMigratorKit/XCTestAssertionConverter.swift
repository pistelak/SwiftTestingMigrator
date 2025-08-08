import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

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
        case "XCTFail":
            return convertXCTFail(node)
        default:
            return nil
        }
    }

    static func convertXCTAssertEqual(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard node.arguments.count >= 2 else { return node }

        guard let firstArg = node.arguments.first,
              let secondArg = node.arguments.dropFirst().first else { return node }

        let equalityExpr = InfixOperatorExprSyntax(
            leftOperand: firstArg.expression,
            operator: BinaryOperatorExprSyntax(operator: .binaryOperator("==", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
            rightOperand: secondArg.expression
        )

        return createExpectCall(with: ExprSyntax(equalityExpr))
    }

    static func convertXCTAssertTrue(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard let firstArg = node.arguments.first else { return node }

        let finalExpression: ExprSyntax
        if needsExplicitBooleanComparison(firstArg.expression) {
            // Simple boolean property - add == true
            finalExpression = ExprSyntax(InfixOperatorExprSyntax(
                leftOperand: firstArg.expression,
                operator: BinaryOperatorExprSyntax(operator: .binaryOperator("==", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
                rightOperand: BooleanLiteralExprSyntax(literal: .keyword(.true))
            ))
        } else {
            // Complex expression - use as-is
            finalExpression = firstArg.expression
        }

        return createExpectCall(with: finalExpression)
    }

    static func convertXCTAssertFalse(_ node: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        guard let firstArg = node.arguments.first else { return node }

        let finalExpression: ExprSyntax
        if needsExplicitBooleanComparison(firstArg.expression) {
            // Simple boolean property - add == true
            finalExpression = ExprSyntax(InfixOperatorExprSyntax(
                leftOperand: firstArg.expression,
                operator: BinaryOperatorExprSyntax(operator: .binaryOperator("==", leadingTrivia: [.spaces(1)], trailingTrivia: [.spaces(1)])),
                rightOperand: BooleanLiteralExprSyntax(literal: .keyword(.false))
            ))
        } else {
            // Complex expression - use as-is
            finalExpression = firstArg.expression
        }

        return createExpectCall(with: finalExpression)
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

    /// Determines if an expression needs explicit boolean comparison for XCTAssertTrue
    /// Returns true for simple identifiers/member access, false for complex expressions
    private static func needsExplicitBooleanComparison(_ expression: ExprSyntax) -> Bool {
        // For XCTAssertTrue only:
        // Simple cases that need explicit comparison (== true):
        // - Identifiers: `isValid`
        // - Member access: `user.isActive`, `items.isEmpty`
        // - Function calls: `isEnabled()`, `getValue()`

        // Complex cases that don't need explicit comparison (use as-is):
        // - Already have comparison operators: `value > 5`, `count == 0`
        // - Logical operators: `a && b`, `!condition`
        // - Other binary operators: `x + y`, `a - b`

        if expression.is(InfixOperatorExprSyntax.self) {
            // Already has an operator - don't add == true
            return false
        }

        if expression.is(PrefixOperatorExprSyntax.self) {
            // Already has a prefix operator (like !) - don't add == true
            return false
        }

        // Check the string representation for operators (fallback for when AST structure isn't precise)
        let exprString = expression.description.trimmingCharacters(in: .whitespaces)

        // If it contains operators, it's likely a complex expression
        let operators = [">", "<", ">=", "<=", "==", "!=", "&&", "||", "+", "-", "*", "/", "%", "!"]
        for operatorSymbol in operators {
            if exprString.contains(" \(operatorSymbol) ") || exprString.hasPrefix("\(operatorSymbol) ") {
                return false // Complex expression - don't add == true
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
