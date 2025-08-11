import Foundation
import Testing

struct FolderParameterTests {
  @Test
  func migratesFolderWithSummary() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let convertibleURL = tempDir.appendingPathComponent("ConvertibleTests.swift")
    let convertibleContent = """
    import XCTest
    final class FooTests: XCTestCase {
      func testExample() {
        XCTAssertTrue(true)
      }
    }
    """
    try convertibleContent.write(to: convertibleURL, atomically: true, encoding: .utf8)

    let alreadyURL = tempDir.appendingPathComponent("AlreadyMigrated.swift")
    let alreadyContent = """
    import Testing

    @Test func already() {
      #expect(true)
    }
    """
    try alreadyContent.write(to: alreadyURL, atomically: true, encoding: .utf8)

    let unsupportedURL = tempDir.appendingPathComponent("UnsupportedTests.swift")
    let unsupportedContent = """
    import XCTest
    final class BarTests: XCTestCase {
      func testExpectation() {
        let e = expectation(description: "A")
        waitForExpectations(timeout: 1)
      }
    }
    """
    try unsupportedContent.write(to: unsupportedURL, atomically: true, encoding: .utf8)

    let process = Process()
    process.executableURL = productsDirectory.appendingPathComponent("SwiftTestingMigrator")
    process.arguments = ["--folder", tempDir.path]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: data, as: UTF8.self)

    #expect(output.contains("ConvertibleTests.swift"))
    #expect(output.contains("AlreadyMigrated.swift"))
    #expect(output.contains("UnsupportedTests.swift"))
    #expect(output.contains("Summary: 1 converted, 1 already migrated, 1 unsupported"))
  }
}

private var productsDirectory: URL {
#if os(macOS)
  for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
    return bundle.bundleURL.deletingLastPathComponent()
  }
  fatalError("couldn't find products directory")
#else
  return Bundle.main.bundleURL
#endif
}
