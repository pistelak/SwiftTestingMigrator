import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder
import SwiftBasicFormat

/// Main interface for migrating XCTest files to Swift Testing
public final class TestMigrator: Sendable {

    public init() {}

    /// Migrate Swift test source code from XCTest to Swift Testing
    /// - Parameter source: The original Swift source code
    /// - Returns: Migrated Swift source code
    /// - Throws: MigrationError if migration fails
    public func migrate(source: String) throws -> String {
        // Parse the source code into AST
        let sourceFile = Parser.parse(source: source)

        // Only migrate XCTest files
        guard containsXCTestCode(sourceFile) else {
            // File doesn't appear to contain XCTest code, return as-is
            return source
        }

        // Fail fast on unsupported expectation patterns
        if containsExpectationUsage(sourceFile) {
            throw MigrationError.unsupportedPattern(
                "XCTest expectations (expectation/waitForExpectations) are not supported"
            )
        }

        // Apply migration transformations
        let migrationRewriter = XCTestToSwiftTestingRewriter()
        let migratedSyntax = migrationRewriter.rewrite(sourceFile)

        // Normalize indentation using SwiftBasicFormat
        let formatter = BasicFormat(indentationWidth: .spaces(2))
        let formattedSyntax = formatter.rewrite(migratedSyntax)

        // Convert back to source code
        let migratedSource = formattedSyntax.description

        return migratedSource
    }

    /// Check if source file contains XCTest code that needs migration
    private func containsXCTestCode(_ sourceFile: SourceFileSyntax) -> Bool {
        let visitor = XCTestDetectionVisitor(viewMode: .sourceAccurate)
        visitor.walk(sourceFile)
        return visitor.hasXCTestCode
    }

    /// Check if source file contains expectation patterns we can't migrate
    private func containsExpectationUsage(_ sourceFile: SourceFileSyntax) -> Bool {
        let visitor = ExpectationUsageVisitor(viewMode: .sourceAccurate)
        visitor.walk(sourceFile)
        return visitor.hasExpectationUsage
    }
}

/// Visitor to detect if file contains XCTest code
private final class XCTestDetectionVisitor: SyntaxVisitor {
    var hasXCTestCode = false

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.path.description.trimmingCharacters(in: .whitespacesAndNewlines) == "XCTest" {
            hasXCTestCode = true
        }
        return .visitChildren
    }

    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        if node.inheritedTypes.contains(where: {
            $0.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "XCTestCase"
        }) {
            hasXCTestCode = true
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if functionName.hasPrefix("XCTAssert") || functionName.hasPrefix("XCTFail") || functionName.hasPrefix("XCTUnwrap") {
            hasXCTestCode = true
        }
        return .visitChildren
    }
}

/// Visitor to detect unsupported expectation usage
private final class ExpectationUsageVisitor: SyntaxVisitor {
    var hasExpectationUsage = false

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if functionName == "expectation" || functionName == "waitForExpectations" {
            hasExpectationUsage = true
        }
        return .visitChildren
    }
}
