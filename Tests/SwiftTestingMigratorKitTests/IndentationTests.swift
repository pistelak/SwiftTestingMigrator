import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct IndentationTests {
    @Test
    func nestedIndentationPreserved() throws {
        let input = """
      import XCTest

      final class NestedTests: XCTestCase {
        func testExample() {
          if true {
            XCTAssertTrue(true)
          }
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct NestedTests {
        @Test
        func example() {
          if true {
            #expect(true == true)
          }
        }
      }
      """
        }
    }

    @Test
    func preservesEmptyLineBetweenTests() throws {
        let input = """
      import XCTest

      final class BlankLineTests: XCTestCase {
        func test_one() {
          XCTAssertTrue(true)
        }

        func test_two() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct BlankLineTests {
        @Test
        func one() {
          #expect(true == true)
        }

        @Test
        func two() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func preservesEmptyLineBetweenExtensionTests() throws {
        let input = """
      import XCTest

      final class ExtensionTests: XCTestCase {}

      extension ExtensionTests {
        func test_one() {
          XCTAssertTrue(true)
        }
        func test_two() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct ExtensionTests {
      }

      extension ExtensionTests {
        @Test
        func one() {
          #expect(true == true)
        }

        @Test
        func two() {
          #expect(true == true)
        }
      }
      """
        }
    }
}
