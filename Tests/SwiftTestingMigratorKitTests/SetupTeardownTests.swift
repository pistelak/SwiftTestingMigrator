import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct SetupTeardownTests {
    @Test
    func setupConvertsToInit() throws {
        let input = """
      import XCTest

      final class SetupTests: XCTestCase {
        private var testData: [String] = []

        override func setUp() {
          super.setUp()
          testData = ["test1", "test2"]
        }

        func testData() {
          XCTAssertEqual(testData.count, 2)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      final class SetupTests {
        private var testData: [String] = []

        init() {
          testData = ["test1", "test2"]
        }

        @Test
        func data() {
          #expect(testData.count == 2)
        }
      }
      """
        }
    }

    @Test
    func teardownConvertsToDeinit() throws {
        let input = """
      import XCTest
      import Combine

      final class TeardownTests: XCTestCase {
        private var subscriptions = Set<AnyCancellable>()

        override func tearDown() {
          subscriptions = []
          super.tearDown()
        }

        func testSubscriptions() {
          XCTAssertNotNil(subscriptions)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing
      import Combine

      final class TeardownTests {
        private var subscriptions = Set<AnyCancellable>()

        deinit {
          subscriptions = []
        }

        @Test
        func subscriptions() {
          #expect(subscriptions != nil)
        }
      }
      """
        }
    }

    @Test
    func bothSetupAndTeardownConversion() throws {
        let input = """
      import XCTest

      final class SetupTeardownTests: XCTestCase {
        private var connection: DatabaseConnection?

        override func setUp() {
          super.setUp()
          connection = DatabaseConnection.connect()
        }

        override func tearDown() {
          connection?.disconnect()
          connection = nil
          super.tearDown()
        }

        func testConnection() {
          XCTAssertNotNil(connection)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      final class SetupTeardownTests {
        private var connection: DatabaseConnection?

        init() {
          connection = DatabaseConnection.connect()
        }

        deinit {
          connection?.disconnect()
          connection = nil
        }

        @Test
        func connection() {
          #expect(connection != nil)
        }
      }
      """
        }
    }

    @Test
    func setupWithoutSuperCall() throws {
        let input = """
      import XCTest

      final class NoSuperSetupTests: XCTestCase {
        private var value: Int = 0

        override func setUp() {
          value = 42
        }

        func testValue() {
          XCTAssertEqual(value, 42)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      final class NoSuperSetupTests {
        private var value: Int = 0

        init() {
          value = 42
        }

        @Test
        func value() {
          #expect(value == 42)
        }
      }
      """
        }
    }

    @Test
    func teardownWithoutSuperCall() throws {
        let input = """
      import XCTest

      final class NoSuperTeardownTests: XCTestCase {
        private var resource: Resource?

        override func tearDown() {
          resource?.cleanup()
        }

        func testResource() {
          XCTAssertNil(resource)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      final class NoSuperTeardownTests {
        private var resource: Resource?

        deinit {
          resource?.cleanup()
        }

        @Test
        func resource() {
          #expect(resource == nil)
        }
      }
      """
        }
    }
}
