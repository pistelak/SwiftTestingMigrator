import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

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

        // Check if this file has any XCTest imports or patterns
        guard containsXCTestCode(sourceFile) else {
            // File doesn't appear to contain XCTest code, return as-is
            return source
        }

        // Apply migration transformations
        let migrationRewriter = XCTestToSwiftTestingRewriter()
        let migratedSyntax = migrationRewriter.rewrite(sourceFile)

        // Convert back to source code with custom formatting
        let migratedSourceFile = migratedSyntax.as(SourceFileSyntax.self)!
        let migratedSource = formatWithCustomStyle(migratedSourceFile)

        return migratedSource
    }

    /// Format syntax tree - preserve original indentation completely
    private func formatWithCustomStyle(_ syntax: SourceFileSyntax) -> String {
        // Don't use syntax.formatted() - it changes indentation
        // Don't trim characters - that removes indentation!
        // Just use the raw description to preserve everything exactly as it was
        return syntax.description
    }


    /// Check if source file contains XCTest code that needs migration
    private func containsXCTestCode(_ sourceFile: SourceFileSyntax) -> Bool {
        let visitor = XCTestDetectionVisitor(viewMode: .sourceAccurate)
        visitor.walk(sourceFile)
        return visitor.hasXCTestCode
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
        for inheritedType in node.inheritedTypes {
            if inheritedType.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "XCTestCase" {
                hasXCTestCode = true
            }
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
