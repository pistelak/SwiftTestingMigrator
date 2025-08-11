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
}
