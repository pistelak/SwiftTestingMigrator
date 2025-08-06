import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct AssertionConversionTests {
  @Test
  func assertTrueWithExplicitBoolean() throws {
    let input = """
      import XCTest
      
      final class BooleanTests: XCTestCase {
        func testTrue() {
          XCTAssertTrue(value > 5)
          XCTAssertTrue(isValid)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct BooleanTests {
        @Test
        func true() {
          #expect(value > 5)
          #expect(isValid == true)
        }
      }
      """
    }
  }
  
  @Test
  func assertFalseWithExplicitBoolean() throws {
    let input = """
      import XCTest
      
      final class BooleanTests: XCTestCase {
        func testFalse() {
          XCTAssertFalse(items.isEmpty)
          XCTAssertFalse(hasError)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct BooleanTests {
        @Test
        func false() {
          #expect(items.isEmpty == false)
          #expect(hasError == false)
        }
      }
      """
    }
  }
  
  @Test
  func assertEqualConversion() throws {
    let input = """
      import XCTest
      
      final class EqualityTests: XCTestCase {
        func testEquality() {
          XCTAssertEqual(actual, expected)
          XCTAssertEqual(count, 42)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct EqualityTests {
        @Test
        func equality() {
          #expect(actual == expected)
          #expect(count == 42)
        }
      }
      """
    }
  }
  
  @Test
  func assertNilConversion() throws {
    let input = """
      import XCTest
      
      final class NilTests: XCTestCase {
        func testNil() {
          XCTAssertNil(optionalValue)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct NilTests {
        @Test
        func nil() {
          #expect(optionalValue == nil)
        }
      }
      """
    }
  }
  
  @Test
  func assertNotNilConversion() throws {
    let input = """
      import XCTest
      
      final class NotNilTests: XCTestCase {
        func testNotNil() {
          XCTAssertNotNil(requiredValue)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct NotNilTests {
        @Test
        func notNil() {
          #expect(requiredValue != nil)
        }
      }
      """
    }
  }
  
  @Test
  func xctFailConversion() throws {
    let input = """
      import XCTest
      
      final class FailTests: XCTestCase {
        func testFail() {
          XCTFail("Something went wrong")
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct FailTests {
        @Test
        func fail() {
          Issue.record("Something went wrong")
        }
      }
      """
    }
  }
  
  @Test
  func complexBooleanExpressions() throws {
    let input = """
      import XCTest
      
      final class ComplexBooleanTests: XCTestCase {
        func testComplexExpressions() {
          XCTAssertTrue(user.isValid && user.isActive)
          XCTAssertFalse(items.isEmpty || hasError)
          XCTAssertTrue(count > 0 && count < 100)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Testing
      
      struct ComplexBooleanTests {
        @Test
        func complexExpressions() {
          #expect(user.isValid && user.isActive)
          #expect(items.isEmpty || hasError)
          #expect(count > 0 && count < 100)
        }
      }
      """
    }
  }
}
