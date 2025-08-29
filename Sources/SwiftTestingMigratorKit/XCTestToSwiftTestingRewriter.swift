import SwiftSyntax
import SwiftSyntaxBuilder

// swiftlint:disable type_body_length
/// Main rewriter that transforms XCTest AST to Swift Testing AST
final class XCTestToSwiftTestingRewriter: SyntaxRewriter {

    private var hasSetUpMethod = false
    private var hasTearDownMethod = false
    private var needsDeinit = false
    private var hasInitOrDeinit = false
    private var hasMemberWithBody = false
    private var hasHelperFunctions = false
    private var testMethodCount = 0
    private var currentTestMethodIndex = 0

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        let processed = super.visit(node)
        return processed.sortedImports()
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        // Replace "import XCTest" with "import Testing"
        let importPath = node.path.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if importPath == "XCTest" {
            let newNode = node.with(\.path, ImportPathComponentListSyntax([
                ImportPathComponentSyntax(name: .identifier("Testing"))
            ]))
            return DeclSyntax(
                newNode
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
            )
        }

        return DeclSyntax(
            node
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
        )
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        // Check if this is an XCTest class
        guard let inheritanceClause = node.inheritanceClause,
              inheritanceClause.inheritedTypes.contains(where: { inheritedType in
                inheritedType.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "XCTestCase"
              }) else {
            return DeclSyntax(node)
        }

        // Pre-analyze the class to determine formatting strategy
        analyzeClassForFormatting(node)

        // Analyze the class to determine if we need class vs struct
        let analyzer = TestClassAnalyzer(viewMode: .sourceAccurate)
        analyzer.walk(node)

        let shouldUseClass = analyzer.needsDeinit || analyzer.hasStoredProperties

        if shouldUseClass {
            // Convert to class without XCTestCase inheritance
            let newInheritanceClause = removeXCTestCaseInheritance(inheritanceClause)

            let convertedClass = node
                .with(\.inheritanceClause, newInheritanceClause)
                .with(\.memberBlock, MemberBlockSyntax(
                    leftBrace: node.memberBlock.leftBrace.with(\.leadingTrivia, [.spaces(1)]), // Ensure space before {
                    members: convertMemberBlock(node.memberBlock, useClass: true).members,
                    rightBrace: node.memberBlock.rightBrace // Preserve original } spacing
                ))
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)

            return DeclSyntax(convertedClass)
        } else {
            // Convert to struct (remove final modifier since structs can't be inherited from)
            let filteredModifiers = node.modifiers.filter { modifier in
                modifier.name.text != "final"
            }

            let structDecl = StructDeclSyntax(
                leadingTrivia: node.leadingTrivia,
                modifiers: filteredModifiers,
                structKeyword: .keyword(.struct),
                name: node.name.with(\.leadingTrivia, [.spaces(1)]), // Ensure space after struct keyword
                genericParameterClause: node.genericParameterClause,
                inheritanceClause: nil, // Structs don't inherit from XCTestCase
                genericWhereClause: node.genericWhereClause,
                memberBlock: MemberBlockSyntax(
                    leftBrace: node.memberBlock.leftBrace.with(\.leadingTrivia, [.spaces(1)]), // Ensure space before {
                    members: convertMemberBlock(node.memberBlock, useClass: false).members,
                    rightBrace: node.memberBlock.rightBrace // Preserve original } spacing
                ),
                trailingTrivia: node.trailingTrivia
            )

            return DeclSyntax(structDecl)
        }
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        // Process computed properties to adjust their indentation
        let newBindings = node.bindings.map { binding in
            if let accessorBlock = binding.accessorBlock {
                let processedAccessorBlock = processAccessorBlock(accessorBlock)
                return binding.with(\.accessorBlock, processedAccessorBlock)
            }
            return binding
        }

        let newNode = node
            .with(\.bindings, PatternBindingListSyntax(newBindings))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        return DeclSyntax(newNode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let functionName = node.name.text

        // Handle test methods
        if functionName.hasPrefix("test") && !functionName.hasPrefix("testable") {
            currentTestMethodIndex += 1
            let convertedMethod = convertTestMethod(node)
            return DeclSyntax(convertedMethod)
        }

        // Handle setUp method
        if functionName == "setUp" {
            return DeclSyntax(convertSetUpMethod(node))
        }

        // Handle tearDown method
        if functionName == "tearDown" {
            return DeclSyntax(convertTearDownMethod(node))
        }

        // For other functions, visit children and return the result
        return super.visit(node)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Convert XCTest assertions
        if let convertedAssertion = XCTestAssertionConverter.convertXCTestAssertion(node, functionName: functionName) {
            return ExprSyntax(convertedAssertion)
        }

        // Convert expectations and waitForExpectations
        if functionName == "expectation" {
            return convertExpectationToConfirmation(node)
        }

        if functionName == "waitForExpectations" {
            return convertWaitForExpectationsToConfirmation(node)
        }

        // For other function calls, visit children and return the result
        return super.visit(node)
    }

    // MARK: - Private Methods

    private func removeXCTestCaseInheritance(_ inheritanceClause: InheritanceClauseSyntax) -> InheritanceClauseSyntax? {
        let filteredTypes = inheritanceClause.inheritedTypes.filter { inheritedType in
            inheritedType.type.description.trimmingCharacters(in: .whitespacesAndNewlines) != "XCTestCase"
        }

        if filteredTypes.isEmpty {
            return nil
        }

        return inheritanceClause.with(\.inheritedTypes, filteredTypes)
    }

    private func convertMemberBlock(_ memberBlock: MemberBlockSyntax, useClass: Bool) -> MemberBlockSyntax {
        // Process each member through the rewriter to ensure functions and other members are converted
        super.visit(memberBlock)
    }

    private func convertTestMethod(_ node: FunctionDeclSyntax) -> FunctionDeclSyntax {
        // Remove "test" prefix from function name
        let originalName = node.name.text
        let newName: String

        if originalName.hasPrefix("test_") {
            newName = String(originalName.dropFirst(5)) // Remove "test_"
        } else if originalName.hasPrefix("test") {
            let nameWithoutTest = String(originalName.dropFirst(4))
            // Convert first letter to lowercase
            newName = nameWithoutTest.prefix(1).lowercased() + nameWithoutTest.dropFirst()
        } else {
            newName = originalName
        }

        // Add @Test attribute with controlled trivia - no extra spacing after @Test
        let testAttribute = AttributeListSyntax([
            .attribute(AttributeSyntax(
                atSign: .atSignToken(),
                attributeName: IdentifierTypeSyntax(name: .identifier("Test")),
                trailingTrivia: [.newlines(1)] // Always single newline after @Test
            ))
        ])

        // Check if function needs async (contains expectation patterns)
        let needsAsync = containsExpectationPatterns(node)

        // Process the function body to convert any assertions inside, but preserve indentation
        // Instead of using super.visit() which can lose trivia, we'll process the body separately
        let processedNode = node.with(\.body, processBody(node.body))

        // Create the function keyword with proper spacing - preserve original indentation but ensure proper format
        let functionKeyword = TokenSyntax(.keyword(.func), leadingTrivia: [.spaces(2)], trailingTrivia: [.spaces(1)], presence: .present)

        // Apply transformations with controlled trivia
        let convertedNode = processedNode
            .with(\.attributes, testAttribute)
            .with(\.funcKeyword, functionKeyword)
            .with(\.name, TokenSyntax.identifier(newName))
            .with(\.signature, needsAsync ? makeAsync(processedNode.signature) : processedNode.signature)

        // Ensure proper spacing before test functions based on context
        // Add empty line before @Test for: 2nd+ test methods when there are multiple tests, or any test when there are special members
        let isFirstTestMethod = (currentTestMethodIndex == 1)
        let hasSpecialMembers = (hasInitOrDeinit || hasMemberWithBody || hasHelperFunctions)
        let needsEmptyLineBefore = hasSpecialMembers || (testMethodCount > 1 && !isFirstTestMethod)

        let properLeadingTrivia: Trivia = needsEmptyLineBefore ? [.newlines(2), .spaces(2)] : [.newlines(1), .spaces(2)]
        return convertedNode
            .with(\.leadingTrivia, properLeadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
    }

    private func convertSetUpMethod(_ node: FunctionDeclSyntax) -> InitializerDeclSyntax {
        // Convert setUp() to init() with proper spacing
        let initDecl = InitializerDeclSyntax(
            leadingTrivia: [.newlines(2), .spaces(2)], // Empty line before init
            modifiers: DeclModifierListSyntax(),
            initKeyword: .keyword(.`init`),
            optionalMark: nil,
            genericParameterClause: nil,
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    leftParen: node.signature.parameterClause.leftParen, // Preserve original ( trivia
                    parameters: FunctionParameterListSyntax([]),
                    rightParen: node.signature.parameterClause.rightParen // Preserve original ) trivia
                ),
                effectSpecifiers: nil,
                returnClause: nil
            ),
            genericWhereClause: nil,
            body: convertSetUpBody(node.body), // Process body to remove super.setUp() but preserve trivia
            trailingTrivia: node.trailingTrivia
        )

        return initDecl
    }

    private func convertTearDownMethod(_ node: FunctionDeclSyntax) -> DeinitializerDeclSyntax {
        needsDeinit = true

        // First process the body through the rewriter to handle any nested expressions
        let visitedNode = super.visit(node)
        guard let processedNode = visitedNode.as(FunctionDeclSyntax.self) else {
            return DeinitializerDeclSyntax(
                leadingTrivia: [.newlines(2), .spaces(2)], // Empty line before deinit
                modifiers: DeclModifierListSyntax(),
                deinitKeyword: TokenSyntax(.keyword(.deinit), trailingTrivia: [.spaces(1)], presence: .present),
                body: convertTearDownBody(node.body), // Process body to remove super.tearDown() calls
                trailingTrivia: node.trailingTrivia
            )
        }

        // Convert tearDown() to deinit with proper spacing
        let deinitDecl = DeinitializerDeclSyntax(
            leadingTrivia: [.newlines(2), .spaces(2)], // Empty line before deinit
            modifiers: DeclModifierListSyntax(),
            deinitKeyword: TokenSyntax(.keyword(.deinit), trailingTrivia: [.spaces(1)], presence: .present),
            body: convertTearDownBody(processedNode.body), // Process body to remove super.tearDown() calls
            trailingTrivia: processedNode.trailingTrivia
        )

        return deinitDecl
    }

    private func convertSetUpBody(_ body: CodeBlockSyntax?) -> CodeBlockSyntax? {
        guard let body = body else { return nil }

        // Remove super.setUp() calls while ensuring proper indentation
        let filteredStatements = body.statements.compactMap { statement -> CodeBlockItemSyntax? in
            // Check the entire statement description for super.setUp
            let statementDescription = statement.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if statementDescription.contains("super.setUp") {
                return nil // Remove super.setUp() call
            }
            // Preserve original trivia for remaining statements
            return statement
                .with(\.leadingTrivia, statement.leadingTrivia)
                .with(\.trailingTrivia, statement.trailingTrivia)
        }

        return body.with(\.statements, CodeBlockItemListSyntax(filteredStatements))
    }

    private func convertTearDownBody(_ body: CodeBlockSyntax?) -> CodeBlockSyntax? {
        guard let body = body else { return nil }

        // Remove super.tearDown() calls while ensuring proper indentation
        let filteredStatements = body.statements.compactMap { statement -> CodeBlockItemSyntax? in
            let statementDescription = statement.description.trimmingCharacters(in: .whitespacesAndNewlines)
            // Remove any statement containing super.tearDown
            if statementDescription.contains("super.tearDown") {
                return nil
            }
            // Preserve original trivia for remaining statements
            return statement
                .with(\.leadingTrivia, statement.leadingTrivia)
                .with(\.trailingTrivia, statement.trailingTrivia)
        }

        return body.with(\.statements, CodeBlockItemListSyntax(filteredStatements))
    }

    private func makeAsync(_ signature: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
        let effectSpecifiers = FunctionEffectSpecifiersSyntax(
            asyncSpecifier: .keyword(.async),
            throwsClause: signature.effectSpecifiers?.throwsClause
        )

        return signature.with(\.effectSpecifiers, effectSpecifiers)
    }

    private func containsExpectationPatterns(_ node: FunctionDeclSyntax) -> Bool {
        let visitor = ExpectationPatternVisitor(viewMode: .sourceAccurate)
        visitor.walk(node)
        return visitor.hasExpectationPatterns
    }

    private func convertExpectationToConfirmation(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // This is complex - for now return as-is and let confirmation handle it
        return ExprSyntax(node)
    }

    private func convertWaitForExpectationsToConfirmation(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // This is complex - for now return as-is and let confirmation handle it
        return ExprSyntax(node)
    }

    private func shouldHaveEmptyLineBeforeTest(_ node: FunctionDeclSyntax) -> Bool {
        // For now, always add an empty line before test methods
        // This ensures proper spacing between init/deinit and test methods
        // In the future, we could analyze the node's position to be more precise
        return true
    }

    private func processBody(_ body: CodeBlockSyntax?) -> CodeBlockSyntax? {
        guard let body = body else { return nil }

        // Process each statement individually while ensuring proper indentation
        let processedStatements = body.statements.map { statement in
            // Create a mini-rewriter for just this statement
            let statementRewriter = AssertionRewriter()
            let processedStatement = statementRewriter.visit(statement)

            // Preserve original trivia for the statement
            return processedStatement
                .with(\.leadingTrivia, statement.leadingTrivia)
                .with(\.trailingTrivia, statement.trailingTrivia)
        }

        return body.with(\.statements, CodeBlockItemListSyntax(processedStatements))
    }

    private func processAccessorBlock(_ accessorBlock: AccessorBlockSyntax) -> AccessorBlockSyntax {
        // Process the accessor block to apply proper indentation to its contents
        switch accessorBlock.accessors {
        case .accessors(let accessorDeclList):
            let processedAccessors = accessorDeclList.map { accessor in
                if let body = accessor.body {
                    let processedBody = processBody(body)
                    return accessor
                        .with(\.body, processedBody)
                        .with(\.leadingTrivia, accessor.leadingTrivia)
                        .with(\.trailingTrivia, accessor.trailingTrivia)
                }
                return accessor
            }
            return accessorBlock.with(\.accessors, .accessors(AccessorDeclListSyntax(processedAccessors)))
        case .getter(let codeBlockItemList):
            // Process each statement in the getter body
            let processedStatements = codeBlockItemList.map { statement in
                let statementRewriter = AssertionRewriter()
                let processedStatement = statementRewriter.visit(statement)
                return processedStatement
                    .with(\.leadingTrivia, statement.leadingTrivia)
                    .with(\.trailingTrivia, statement.trailingTrivia)
            }
            return accessorBlock.with(\.accessors, .getter(CodeBlockItemListSyntax(processedStatements)))
        }
    }

    private func analyzeClassForFormatting(_ classNode: ClassDeclSyntax) {
        // Reset flags
        hasSetUpMethod = false
        hasTearDownMethod = false
        needsDeinit = false
        hasInitOrDeinit = false
        hasMemberWithBody = false
        hasHelperFunctions = false
        testMethodCount = 0
        currentTestMethodIndex = 0

        // Walk through all members to count and categorize them
        for member in classNode.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                let functionName = functionDecl.name.text

                if functionName.hasPrefix("test") && !functionName.hasPrefix("testable") {
                    testMethodCount += 1
                } else if functionName == "setUp" {
                    hasSetUpMethod = true
                    hasInitOrDeinit = true
                    hasMemberWithBody = true
                } else if functionName == "tearDown" {
                    hasTearDownMethod = true
                    hasInitOrDeinit = true
                    hasMemberWithBody = true
                } else if !functionName.hasPrefix("test") || functionName.hasPrefix("testable") {
                    hasHelperFunctions = true
                }
            } else if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check for computed properties
                if variableDecl.bindings.contains(where: { $0.accessorBlock != nil }) {
                    hasMemberWithBody = true
                }
            }
        }
    }

}
// swiftlint:enable type_body_length

/// Helper rewriter that only converts assertions while preserving trivia
private final class AssertionRewriter: SyntaxRewriter {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Convert XCTest assertions using the shared converter
        if let convertedAssertion = XCTestAssertionConverter.convertXCTestAssertion(node, functionName: functionName) {
            return ExprSyntax(convertedAssertion)
        }

        // For other function calls, continue visiting children to ensure nested
        // assertions are properly processed
        return super.visit(node)
    }
}

/// Helper visitor to detect expectation patterns
private final class ExpectationPatternVisitor: SyntaxVisitor {
    var hasExpectationPatterns = false

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if functionName == "expectation" || functionName == "waitForExpectations" {
            hasExpectationPatterns = true
        }
        return .visitChildren
    }
}

/// Helper class to analyze test class and determine struct vs class
private final class TestClassAnalyzer: SyntaxVisitor {
    var needsDeinit = false
    var hasStoredProperties = false
    private var functionDepth = 0

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        functionDepth += 1
        if node.name.text == "tearDown" {
            needsDeinit = true
        }
        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        functionDepth -= 1
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Only check for stored properties at class level (not inside functions)
        if functionDepth == 0 {
            for binding in node.bindings {
                if binding.accessorBlock == nil && binding.initializer != nil {
                    hasStoredProperties = true
                }
            }
        }
        return .visitChildren
    }
}
