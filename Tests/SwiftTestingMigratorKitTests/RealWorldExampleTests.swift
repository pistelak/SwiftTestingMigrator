import Testing
import InlineSnapshotTesting
@testable import SwiftTestingMigratorKit

struct RealWorldExampleTests {
  @Test
  func realWorldDataConverter() throws {
    let input = """
      import DataProcessorKit
      @testable import CoreModel
      import XCTest
      
      final class DataConverterTests: XCTestCase {
        func test_external_to_domain_conversion() throws {
          let converter = DataProcessorV3Converter(
            typeConverter: .live,
            valueConverter: .live(formatConverter: .live)
          )
          XCTAssertEqual(
            try converter.domainModel(
              fromExternal: .init(
                startTime: "11:20",
                endTime: "13:40",
                entries: [.init(type: "STANDARD", value: "XYZ123", amount: 42)]
              )
            ),
            .init(
              startTime: DateComponents(hour: 11, minute: 20),
              endTime: DateComponents(hour: 13, minute: 40),
              entries: [.init(type: .standard, value: .custom("XYZ123"), amount: 42)]
            )
          )
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import DataProcessorKit
      @testable import CoreModel
      import Testing
      
      struct DataConverterTests {
        @Test
        func external_to_domain_conversion() throws {
          let converter = DataProcessorV3Converter(
            typeConverter: .live,
            valueConverter: .live(formatConverter: .live)
          )
          #expect(
            try converter.domainModel(
              fromExternal: .init(
                startTime: "11:20",
                endTime: "13:40",
                entries: [.init(type: "STANDARD", value: "XYZ123", amount: 42)]
              )
            ) ==
            .init(
              startTime: DateComponents(hour: 11, minute: 20),
              endTime: DateComponents(hour: 13, minute: 40),
              entries: [.init(type: .standard, value: .custom("XYZ123"), amount: 42)]
            ))
        }
      }
      """
    }
  }
  
  @Test
  func tcaTestStoreExample() throws {
    let input = """
      import ComposableArchitecture
      import XCTest
      @testable import MyFeature
      
      final class FeatureTests: XCTestCase {
        func test_increment_action() async {
          let store = TestStore(initialState: Feature.State(count: 0)) {
            Feature()
          }
          
          await store.send(.increment) {
            $0.count = 1
          }
          
          await store.send(.increment) {
            $0.count = 2
          }
        }
        
        func test_decrement_action() async {
          let store = TestStore(initialState: Feature.State(count: 5)) {
            Feature()
          }
          
          await store.send(.decrement) {
            $0.count = 4
          }
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import ComposableArchitecture
      import Testing
      @testable import MyFeature
      
      struct FeatureTests {
        @Test
        func increment_action() async {
          let store = TestStore(initialState: Feature.State(count: 0)) {
            Feature()
          }
      
          await store.send(.increment) {
            $0.count = 1
          }
      
          await store.send(.increment) {
            $0.count = 2
          }
        }

        @Test
        func decrement_action() async {
          let store = TestStore(initialState: Feature.State(count: 5)) {
            Feature()
          }
      
          await store.send(.decrement) {
            $0.count = 4
          }
        }
      }
      """
    }
  }
  
  @Test
  func asyncTestingWithDependencies() throws {
    let input = """
      import ComposableArchitecture
      import XCTest
      @testable import NetworkFeature
      
      final class NetworkFeatureTests: XCTestCase {
        func test_fetch_data_success() async {
          let store = TestStore(initialState: NetworkFeature.State()) {
            NetworkFeature()
          } withDependencies: {
            $0.apiClient.fetchData = { @MainActor in
              return Data("success".utf8)
            }
          }
          
          await store.send(.fetchData)
          await store.receive(.dataReceived(.success(Data("success".utf8)))) {
            $0.isLoading = false
            $0.data = Data("success".utf8)
          }
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)
    
    
    assertInlineSnapshot(of: result, as: .lines) {
      """
      import ComposableArchitecture
      import Testing
      @testable import NetworkFeature
      
      struct NetworkFeatureTests {
        @Test
        func fetch_data_success() async {
          let store = TestStore(initialState: NetworkFeature.State()) {
            NetworkFeature()
          } withDependencies: {
            $0.apiClient.fetchData = { @MainActor in
              return Data("success".utf8)
            }
          }
      
          await store.send(.fetchData)
          await store.receive(.dataReceived(.success(Data("success".utf8)))) {
            $0.isLoading = false
            $0.data = Data("success".utf8)
          }
        }
      }
      """
    }
  }
  
  @Test
  func complexTestWithMultipleImportsAndPatterns() throws {
    let input = """
      import Foundation
      import Combine
      import ComposableArchitecture
      import XCTest
      @testable import UserManagement
      @testable import AuthService
      
      final class UserManagementTests: XCTestCase {
        private var cancellables: Set<AnyCancellable> = []
        
        override func tearDown() {
          cancellables.removeAll()
          super.tearDown()
        }
        
        func test_user_login_flow() async throws {
          let mockAuthService = MockAuthService()
          let store = TestStore(initialState: UserManagement.State()) {
            UserManagement()
          } withDependencies: {
            $0.authService = mockAuthService
          }
          
          await store.send(.loginButtonTapped) {
            $0.isLoggingIn = true
          }
          
          await store.receive(.loginResponse(.success(.init(id: "123", name: "John")))) {
            $0.isLoggingIn = false
            $0.user = User(id: "123", name: "John")
            $0.isLoggedIn = true
          }
          
          XCTAssertTrue(mockAuthService.loginCalled)
          XCTAssertEqual(store.state.user?.name, "John")
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)

    assertInlineSnapshot(of: result, as: .lines) {
      """
      import Foundation
      import Combine
      import ComposableArchitecture
      import Testing
      @testable import UserManagement
      @testable import AuthService

      final class UserManagementTests {
        private var cancellables: Set<AnyCancellable> = []

        deinit {
          cancellables.removeAll()
        }

        @Test
        func user_login_flow() async throws {
          let mockAuthService = MockAuthService()
          let store = TestStore(initialState: UserManagement.State()) {
            UserManagement()
          } withDependencies: {
            $0.authService = mockAuthService
          }

          await store.send(.loginButtonTapped) {
            $0.isLoggingIn = true
          }

          await store.receive(.loginResponse(.success(.init(id: "123", name: "John")))) {
            $0.isLoggingIn = false
            $0.user = User(id: "123", name: "John")
            $0.isLoggedIn = true
          }

          #expect(mockAuthService.loginCalled == true)
          #expect(store.state.user?.name == "John")
        }
      }
      """
    }
  }
  
  @Test
  func previewSnapshotsTesting() throws {
    let input = """
      import SwiftUI
      import SnapshotTesting
      import XCTest
      @testable import MyApp
      
      final class PreviewSnapshotTests: XCTestCase {
        func test_preview_snapshots() {
          let previews = ContentView_Previews.previews
          
          for preview in previews {
            assertSnapshot(matching: preview, as: .image)
          }
        }
        
        func test_specific_preview_state() {
          let view = ContentView(
            store: Store(initialState: ContentView.State(isLoading: true)) {
              ContentView.Action.self
            }
          )
          
          assertSnapshot(matching: view, as: .image)
          XCTAssertNoThrow(view.body)
        }
      }
      """
    
    let migrator = TestMigrator()
    let result = try migrator.migrate(source: input)

    assertInlineSnapshot(of: result, as: .lines) {
      """
      import SwiftUI
      import SnapshotTesting
      import Testing
      @testable import MyApp

      struct PreviewSnapshotTests {
        @Test
        func preview_snapshots() {
          let previews = ContentView_Previews.previews

          for preview in previews {
            assertSnapshot(matching: preview, as: .image)
          }
        }

        @Test
        func specific_preview_state() {
          let view = ContentView(
            store: Store(initialState: ContentView.State(isLoading: true)) {
              ContentView.Action.self
            }
          )

          assertSnapshot(matching: view, as: .image)
          XCTAssertNoThrow(view.body)
        }
      }
      """
    }
  }
}
