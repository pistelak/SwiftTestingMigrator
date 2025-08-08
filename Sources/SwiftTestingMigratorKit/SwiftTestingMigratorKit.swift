/// SwiftTestingMigratorKit - Library for migrating XCTest to Swift Testing
///
/// This library provides functionality to automatically convert XCTest-based
/// test files to use the Swift Testing framework.

// Re-export public types
@_exported import struct Foundation.URL
@_exported import class Foundation.FileManager

public extension TestMigrator {
    /// Convenience method to migrate a file from path to path
    /// - Parameters:
    ///   - inputPath: Path to input Swift test file
    ///   - outputPath: Path where migrated file should be written (optional, defaults to inputPath)
    /// - Throws: MigrationError if migration fails
    func migrateFile(from inputPath: String, to outputPath: String? = nil) throws {
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath ?? inputPath)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw MigrationError.fileReadError(inputPath)
        }

        let source: String
        do {
            source = try String(contentsOf: inputURL)
        } catch {
            throw MigrationError.fileReadError("Could not read \(inputPath): \(error)")
        }

        let migratedSource = try migrate(source: source)

        do {
            try migratedSource.write(to: outputURL, atomically: true, encoding: .utf8)
        } catch {
            throw MigrationError.fileWriteError("Could not write \(outputURL.path): \(error)")
        }
    }
}
