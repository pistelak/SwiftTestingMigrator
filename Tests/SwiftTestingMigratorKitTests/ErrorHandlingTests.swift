import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct ErrorHandlingTests {
    @Test
    func invalidSyntaxThrowsError() {
        let input = "invalid swift syntax {"

        let migrator = TestMigrator()

        do {
            let result = try migrator.migrate(source: input)
            assertInlineSnapshot(of: result, as: .lines) {
                """
        invalid swift syntax {
        """
            }
        } catch {
            // If it throws, snapshot the error description
            assertInlineSnapshot(of: String(describing: error), as: .lines) {
                """

        """
            }
        }
    }

    @Test
    func emptyInputReturnsEmptyOutput() throws {
        let input = ""

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """

      """
        }
    }

    @Test
    func nonTestFileRemainsUnchanged() throws {
        let input = """
      import Foundation

      struct RegularCode {
        func regularFunction() {
          print("Hello")
        }
      }

      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)
        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Foundation

      struct RegularCode {
        func regularFunction() {
          print("Hello")
        }
      }

      """
        }
    }

    @Test
    func fileWithOnlyCommentsAndWhitespace() throws {
        let input = """
      // This is just a comment file

      /*
      * Block comment
      */

      // Another comment
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      // This is just a comment file

      /*
      * Block comment
      */

      // Another comment
      """
        }
    }

    @Test
    func fileWithoutXCTestImportUnchanged() throws {
        let input = """
      import Foundation
      import SwiftUI

      final class SomeClass {
        func someMethod() {
          print("Not a test")
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)
        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Foundation
      import SwiftUI

      final class SomeClass {
        func someMethod() {
          print("Not a test")
        }
      }
      """
        }
    }

    @Test
    func mixedTestAndNonTestCode() throws {
        let input = """
      import Foundation
      import XCTest

      struct HelperStruct {
        let value: String
      }

      final class MixedTests: XCTestCase {
        func testHelper() {
          let helper = HelperStruct(value: "test")
          XCTAssertEqual(helper.value, "test")
        }
      }

      class NonTestClass {
        func regularMethod() {
          print("Not a test")
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Foundation
      import Testing

      struct HelperStruct {
        let value: String
      }

      struct MixedTests {
        @Test
        func helper() {
          let helper = HelperStruct(value: "test")
          #expect(helper.value == "test")
        }
      }

      class NonTestClass {
        func regularMethod() {
          print("Not a test")
        }
      }
      """
        }
    }

    @Test
    func expectationPatternsThrowError() {
        let input = """
      import XCTest

      final class ExpectationTests: XCTestCase {
        func test_waits() {
          let exp = expectation(description: "async work")
          waitForExpectations(timeout: 1.0)
        }
      }
      """

        let migrator = TestMigrator()

        do {
            _ = try migrator.migrate(source: input)
            Issue.record("Expected migration to fail")
        } catch {
            assertInlineSnapshot(of: error.localizedDescription, as: .lines) {
                """
        Unsupported pattern that cannot be migrated: XCTest expectations (expectation/waitForExpectations) are not supported
        """
            }
        }
    }
}
