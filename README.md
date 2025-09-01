# SwiftTestingMigrator

SwiftTestingMigrator is a command-line tool that converts XCTest-based test files to the
Swift Testing framework. It performs conservative transformations so that the migrated
code stays familiar and easy to review.

## Features

- **Conservative migration** – keeps code structure intact and minimizes edits
- **XCTest ➜ Swift Testing** – updates imports, test declarations, and assertions
- **Smart class/struct decisions** – chooses `struct` when possible, `class` when
  stored properties or teardown logic require it
- **Setup/teardown migration** – converts `setUp`/`tearDown` to `init`/`deinit`
- **Comprehensive assertion mapping** – covers the most common XCTest assertions
- **Early failure for unsupported expectations** – files using `expectation` or
  `waitForExpectations` produce a clear error message rather than an incorrect migration
  (can be overridden with `--force`)

## Installation

### Build from source

```bash
git clone <repository-url>
cd SwiftTestingMigrator
swift build -c release
```

## Usage

```bash
# Basic migration (overwrites original file)
SwiftTestingMigrator --file MyTests.swift

# Preview changes without writing
SwiftTestingMigrator --file MyTests.swift --dry-run

# Migrate to a different output file
SwiftTestingMigrator --file MyTests.swift --output MigratedTests.swift

# Create backup before migration
SwiftTestingMigrator --file MyTests.swift --backup

# Verbose output
SwiftTestingMigrator --file MyTests.swift --verbose

# Force migration even if unsupported patterns are found
SwiftTestingMigrator --file MyTests.swift --force
```

## Examples

### Basic test class

**Before**

```swift
import XCTest

final class SimpleTests: XCTestCase {
  func testExample() {
    XCTAssertTrue(true)
    XCTAssertEqual(1, 1)
  }
}
```

**After**

```swift
import Testing

struct SimpleTests {
  @Test func example() {
    #expect(true)
    #expect(1 == 1)
  }
}
```

### Class with properties

**Before**

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
    XCTAssertTrue(true)
  }
}
```

**After**

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

  @Test
  func api_call_success() {
    #expect(true)
  }
}
```

## Limitations

- XCTest `expectation`/`waitForExpectations` APIs are not yet fully supported. The tool
  will exit with an error when they are detected unless `--force` is used.
- UI automation tests (`XCUIApplication`)
- Performance tests (`XCTMetric`)
- Objective-C test code

## Development

### Running tests

```bash
swift test
```

### Architecture

- **SwiftTestingMigratorKit** – core migration library using SwiftSyntax
- **SwiftTestingMigrator** – command-line interface built with Swift Argument Parser
- **XCTestToSwiftTestingRewriter** – main AST transformation logic

## Contributing

1. Follow the project's conservative migration approach
2. Add tests for new patterns
3. Maintain compatibility with Swift 6 and modern concurrency
4. Match the existing code style

## License

SwiftTestingMigrator is released under the [MIT License](LICENSE).

