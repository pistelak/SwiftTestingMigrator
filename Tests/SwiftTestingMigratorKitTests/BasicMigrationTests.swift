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
    func importsAreSorted() throws {
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
      import Combine
      import Foundation
      import Testing

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
    func testableImportsSortedWithoutBlankLine() throws {
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
      @testable import MyModule
      import Testing

      struct TestableImportTests {
        @Test
        func feature() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func testableImportsMaintainSeparationWithBlankLine() throws {
        let input = """
      import Foundation
      import XCTest

      @testable import ZModule
      @testable import AModule

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
      import Foundation
      import Testing

      @testable import AModule
      @testable import ZModule

      struct TestableImportTests {
        @Test
        func feature() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func mainActorAnnotationPreserved() throws {
        let input = """
      import XCTest

      final class MainActorTests: XCTestCase {
        @MainActor func testOnMainActor() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct MainActorTests {
        @MainActor
        @Test
        func onMainActor() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func mainActorRemovalOption() throws {
        let input = """
      import XCTest

      final class MainActorTests: XCTestCase {
        @MainActor func testOnMainActor() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator(removeMainActor: true)
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct MainActorTests {
        @Test
        func onMainActor() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func mainActorPreservedWithOtherAttributes() throws {
        let input = """
      import XCTest

      final class MainActorAvailabilityTests: XCTestCase {
        @available(*, deprecated)
        @MainActor func testOnMainActor() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator()
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct MainActorAvailabilityTests {
        @available(*, deprecated)
        @MainActor
        @Test
        func onMainActor() {
          #expect(true == true)
        }
      }
      """
        }
    }

    @Test
    func mainActorRemovalWithOtherAttributes() throws {
        let input = """
      import XCTest

      final class MainActorAvailabilityTests: XCTestCase {
        @available(*, deprecated)
        @MainActor func testOnMainActor() {
          XCTAssertTrue(true)
        }
      }
      """

        let migrator = TestMigrator(removeMainActor: true)
        let result = try migrator.migrate(source: input)

        assertInlineSnapshot(of: result, as: .lines) {
            """
      import Testing

      struct MainActorAvailabilityTests {
        @available(*, deprecated)
        @Test
        func onMainActor() {
          #expect(true == true)
        }
      }
      """
        }
    }
}
