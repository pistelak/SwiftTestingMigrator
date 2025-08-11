import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct TestMethodNamingTests {
    @Test
    func camelCaseMethodConversion() throws {
        let input = """
      import XCTest

      final class NamingTests: XCTestCase {
        func testCamelCaseMethod() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct NamingTests {
        @Test
        func camelCaseMethod() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func snakeCaseMethodConversion() throws {
        let input = """
      import XCTest

      final class NamingTests: XCTestCase {
        func test_snake_case_method() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct NamingTests {
        @Test
        func snake_case_method() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func multipleTestMethods() throws {
        let input = """
      import XCTest

      final class MultipleTests: XCTestCase {
        func test_snake_case_method() {
          XCTAssertTrue(true)
        }

        func testCamelCaseMethod() {
          XCTAssertFalse(false)
        }

        func test_with_parameters() throws {
          XCTAssertEqual("hello", "hello")
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct MultipleTests {
        @Test
        func snake_case_method() {
          #expect(true == true)
        }

        @Test
        func camelCaseMethod() {
          #expect(false == false)
        }

        @Test
        func with_parameters() throws {
          #expect("hello" == "hello")
        }
      }
      """
        }
    }

    @Test
    func methodWithThrows() throws {
        let input = """
      import XCTest

      final class ThrowingTests: XCTestCase {
        func testSomethingThatThrows() throws {
          XCTAssertEqual(try riskyOperation(), "success")
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct ThrowingTests {
        @Test
        func somethingThatThrows() throws {
          #expect(try riskyOperation() == "success")
        }
      }
      """
        }
    }

    @Test
    func methodWithAsync() throws {
        let input = """
      import XCTest

      final class AsyncTests: XCTestCase {
        func testAsyncOperation() async throws {
          let result = await asyncOperation()
          XCTAssertEqual(result, "done")
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct AsyncTests {
        @Test
        func asyncOperation() async throws {
          let result = await asyncOperation()
          #expect(result == "done")
        }
      }
      """
        }
    }
}
