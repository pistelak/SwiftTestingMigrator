import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct BasicMigrationTests {
    @Test
    func importConversion() throws {
        let input = """
      import XCTest

      final class SimpleTests: XCTestCase {
        func testExample() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct SimpleTests {
        @Test
        func example() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func classToStructConversion() throws {
        let input = """
      import XCTest

      final class SimpleTests: XCTestCase {
        func testExample() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct SimpleTests {
        @Test
        func example() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func testMethodConversion() throws {
        let input = """
      import XCTest

      final class SimpleTests: XCTestCase {
        func testExample() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct SimpleTests {
        @Test
        func example() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func multipleImportsPreserved() throws {
        let input = """
      import Foundation
      import XCTest
      import Combine

      final class MultiImportTests: XCTestCase {
        func testSomething() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Foundation
      import Testing
      import Combine

      struct MultiImportTests {
        @Test
        func something() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func testableImportsPreserved() throws {
        let input = """
      import XCTest
      @testable import MyModule

      final class TestableImportTests: XCTestCase {
        func testFeature() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing
      @testable import MyModule

      struct TestableImportTests {
        @Test
        func feature() {
          #expect(true == true)
        }
      }
      """
        }
    }
}
