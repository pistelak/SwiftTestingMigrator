import Testing
import InlineSnapshotTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser
@testable import SwiftTestingMigratorKit

struct XCTestAssertionConverterTests {

    @Test
    func convertXCTAssertEqual() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertEqual",
            arguments: ["actual", "expected"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertEqual")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(actual == expected)
      """
        }
    }

    @Test
    func convertXCTAssertEqualWithLiterals() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertEqual",
            arguments: ["count", "42"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertEqual")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(count == 42)
      """
        }
    }

    @Test
    func convertXCTAssertEqualWithEmptyString() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertEqual",
            arguments: ["stringValue", "\"\""]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertEqual")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(stringValue.isEmpty == true)
      """
        }
    }

    @Test
    func convertXCTAssertTrue() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertTrue",
            arguments: ["isValid"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertTrue")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(isValid == true)
      """
        }
    }

    @Test
    func convertXCTAssertTrueWithComplexExpression() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertTrue",
            arguments: ["value > 5"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertTrue")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(value > 5)
      """
        }
    }

    @Test
    func convertXCTAssertTrueWithEmptyStringComparison() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertTrue",
            arguments: ["value == \"\""]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertTrue")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(value.isEmpty == true)
      """
        }
    }

    @Test
    func convertXCTAssertFalse() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertFalse",
            arguments: ["isEmpty"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertFalse")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(isEmpty == false)
      """
        }
    }

    @Test
    func convertXCTAssertFalseWithComplexExpression() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertFalse",
            arguments: ["items.isEmpty || hasError"]
        )

        let result = XCTestAssertionConverter.convertXCTAssertFalse(functionCall)
        let output = result.description

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(items.isEmpty || hasError)
      """
        }
    }

    @Test
    func convertXCTAssertFalseWithEmptyStringComparison() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertFalse",
            arguments: ["value == \"\""]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertFalse")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(value.isEmpty == false)
      """
        }
    }

    @Test
    func convertXCTAssertNil() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertNil",
            arguments: ["optionalValue"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertNil")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(optionalValue == nil)
      """
        }
    }

    @Test
    func convertXCTAssertNotNil() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertNotNil",
            arguments: ["requiredValue"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertNotNil")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      #expect(requiredValue != nil)
      """
        }
    }

    @Test
    func convertXCTFail() throws {
        let functionCall = createFunctionCall(
            name: "XCTFail",
            arguments: ["\"Something went wrong\""]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTFail")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      Issue.record("Something went wrong")
      """
        }
    }

    @Test
    func convertXCTFailWithoutMessage() throws {
        let functionCall = createFunctionCall(
            name: "XCTFail",
            arguments: []
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTFail")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      Issue.record()
      """
        }
    }

    @Test
    func convertUnknownAssertion() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertSomething",
            arguments: ["value"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertSomething")

        #expect(result == nil)
    }

    @Test
    func convertXCTAssertEqualWithInsufficientArguments() throws {
        let functionCall = createFunctionCall(
            name: "XCTAssertEqual",
            arguments: ["single"]
        )

        let result = XCTestAssertionConverter.convertXCTestAssertion(functionCall, functionName: "XCTAssertEqual")
        let output = result?.description ?? ""

        assertInlineSnapshot(of: output, as: .lines) {
            """
      XCTAssertEqual(single)
      """
        }
    }
}

// MARK: - Helper Functions

/// Simple helper to create function calls for testing - much cleaner than before!
private func createFunctionCall(name: String, arguments: [String]) -> FunctionCallExprSyntax {
    let source = "\(name)(\(arguments.joined(separator: ", ")))"
    let parsed = Parser.parse(source: source)
    guard let call = parsed.statements.first?.item.as(FunctionCallExprSyntax.self) else {
        preconditionFailure("Failed to parse function call: \(source)")
    }
    return call
}
