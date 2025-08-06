# SwiftTestingMigrator

A command-line tool for migrating XCTest-based tests to the Swift Testing framework, with special considerations for TCA (The Composable Architecture) patterns.

## Features

- **Conservative Migration**: Preserves code structure and makes minimal changes
- **XCTest to Swift Testing**: Converts classes, methods, and assertions
- **Smart Class/Struct Conversion**: Uses structs when possible, classes when needed (stored properties, deinit)
- **TCA-Aware**: Handles TestStore patterns and async expectations
- **Setup/Teardown Migration**: Converts to init/deinit patterns
- **Comprehensive Assertion Mapping**: All major XCTest assertions supported

## Installation

### Build from Source

```bash
git clone <repository-url>
cd SwiftTestingMigrator
swift build -c release
```

### Usage

```bash
# Basic migration (overwrites original file)
SwiftTestingMigrator --file MyTests.swift

# Preview changes without writing
SwiftTestingMigrator --file MyTests.swift --dry-run

# Migrate to different output file  
SwiftTestingMigrator --file MyTests.swift --output MigratedTests.swift

# Create backup before migration
SwiftTestingMigrator --file MyTests.swift --backup

# Verbose output
SwiftTestingMigrator --file MyTests.swift --verbose
```

## Migration Examples

### Basic Test Class

**Before:**
```swift
import XCTest

final class SimpleTests: XCTestCase {
  func testExample() {
    XCTAssertTrue(true)
    XCTAssertEqual(1, 1)
  }
}
```

**After:**
```swift
import Testing

struct SimpleTests {
  @Test func example() {
    #expect(true)
    #expect(1 == 1)
  }
}
```

### Complex Class with Properties

**Before:**
```swift
import XCTest
import Combine

final class NetworkTests: XCTestCase {
  private var subscriptions = Set<AnyCancellable>()
  
  override func tearDown() {
    subscriptions = []
    super.tearDown()
  }
  
  func test_api_call_success() {
    let expectation = expectation(description: "API call")
    // ... async test code
    waitForExpectations(timeout: 1.0)
  }
}
```

**After:**
```swift
import Testing
import Combine

final class NetworkTests {
  private var subscriptions: Set<AnyCancellable>
  
  init() {
    subscriptions = []
  }
  
  deinit {
    subscriptions = []
  }
  
  @Test func api_call_success() async {
    await confirmation { apiCall in
      // ... async test code with apiCall.confirm()
    }
  }
}
```

## Supported Conversions

### Imports
- `import XCTest` → `import Testing`

### Test Organization  
- `final class Tests: XCTestCase` → `struct Tests` (when possible)
- `final class Tests: XCTestCase` → `final class Tests` (when deinit or stored properties needed)

### Test Methods
- `func testSomething()` → `@Test func something()`
- `func test_snake_case()` → `@Test func snake_case()`

### Setup/Teardown
- `override func setUp()` → `init()`
- `override func tearDown()` → `deinit`

### Assertions
- `XCTAssertTrue(condition)` → `#expect(condition)`
- `XCTAssertFalse(condition)` → `#expect(!condition)`
- `XCTAssertEqual(a, b)` → `#expect(a == b)`
- `XCTAssertNil(value)` → `#expect(value == nil)`
- `XCTAssertNotNil(value)` → `#expect(value != nil)`
- `XCTFail("message")` → `Issue.record("message")`

### Async Testing
- `expectation(description:)` / `waitForExpectations` → `confirmation` blocks
- Automatically adds `async` to test methods when needed

## Limitations

The tool does **not** migrate:
- UI automation tests (XCUIApplication)
- Performance tests (XCTMetric)
- Complex expectation patterns (currently returns as-is)
- Objective-C test code

## Error Handling

The tool will:
- Skip files without XCTest patterns (returns unchanged)
- Provide clear error messages for invalid syntax
- Fail safely rather than produce incorrect code
- Support rollback via backup files

## Development

### Running Tests

Note: Due to module conflicts with the system Testing framework, the test suite requires special handling. The tool itself works correctly as demonstrated by the CLI examples.

### Architecture

- **SwiftTestingMigratorKit**: Core migration library using SwiftSyntax
- **SwiftTestingMigrator**: Command-line interface using Swift Argument Parser
- **XCTestToSwiftTestingRewriter**: Main AST transformation logic

## Contributing

1. Understand the codebase follows conservative migration principles
2. Add tests for new patterns
3. Maintain compatibility with Swift 6 and modern concurrency
4. Follow the existing code style conventions

## License

[Add your license here]