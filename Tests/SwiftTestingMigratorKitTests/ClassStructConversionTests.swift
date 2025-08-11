import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct ClassStructConversionTests {
    @Test
    func simpleClassConvertsToStruct() throws {
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
    func classWithStoredPropertiesRemainsClass() throws {
        let input = """
      import XCTest
      import Combine

      final class NetworkTests: XCTestCase {
        private var subscriptions = Set<AnyCancellable>()

        override func tearDown() {
          subscriptions = []
          super.tearDown()
        }

        func testNetworkCall() {
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

      final class NetworkTests {
        private var subscriptions = Set<AnyCancellable>()

        deinit {
          subscriptions = []
        }

        @Test
        func networkCall() {
          #expect(subscriptions != nil)
        }
      }
      """
        }
    }

    @Test
    func classWithSetupRemainsClass() throws {
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
    func classWithoutStoredPropertiesConvertsToStruct() throws {
        let input = """
      import XCTest

      final class PureTests: XCTestCase {
        func testPureFunction() {
          let result = add(2, 3)
          XCTAssertEqual(result, 5)
        }

        func testAnotherPureFunction() {
          let result = multiply(4, 5)
          XCTAssertEqual(result, 20)
        }

        private func add(_ a: Int, _ b: Int) -> Int {
          return a + b
        }

        private func multiply(_ a: Int, _ b: Int) -> Int {
          return a * b
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct PureTests {

        @Test
        func pureFunction() {
          let result = add(2, 3)
          #expect(result == 5)
        }

        @Test
        func anotherPureFunction() {
          let result = multiply(4, 5)
          #expect(result == 20)
        }

        private func add(_ a: Int, _ b: Int) -> Int {
          return a + b
        }

        private func multiply(_ a: Int, _ b: Int) -> Int {
          return a * b
        }
      }
      """
        }
    }

    @Test
    func classWithComputedPropertiesConvertsToStruct() throws {
        let input = """
      import XCTest

      final class ComputedPropertyTests: XCTestCase {
        var computedValue: String {
          return "computed"
        }

        func testComputedProperty() {
          XCTAssertEqual(computedValue, "computed")
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct ComputedPropertyTests {
        var computedValue: String {
          return "computed"
        }

        @Test
        func computedProperty() {
          #expect(computedValue == "computed")
        }
      }
      """
        }
    }
}
