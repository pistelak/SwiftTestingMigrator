import ArgumentParser
import Foundation
import SwiftTestingMigratorKit

@main
struct SwiftTestingMigrator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "SwiftTestingMigrator",
        abstract: "A tool to migrate XCTest tests to the Swift Testing framework",
        discussion: """
      This tool performs conservative migration from XCTest to Swift Testing,
      preserving as much of the original code structure as possible while
      converting to modern Swift Testing syntax.

      Examples:
        SwiftTestingMigrator --file MyTests.swift
        SwiftTestingMigrator --file Tests.swift --output MigratedTests.swift --dry-run
      """
    )

    @Option(
        name: .shortAndLong,
        help: "Path to the Swift test file to migrate"
    )
    var file: String

    @Option(
        name: .shortAndLong,
        help: "Output file path (defaults to overwriting input file)"
    )
    var output: String?

    @Flag(
        name: .long,
        help: "Preview changes without writing to file"
    )
    var dryRun = false

    @Flag(
        name: .long,
        help: "Create .backup file before modifying original"
    )
    var backup = false

    @Flag(
        name: .shortAndLong,
        help: "Enable verbose output"
    )
    var verbose = false

    func run() async throws {
        let migrator = TestMigrator()

        if verbose {
            print("🔍 Reading file: \(file)")
        }

        guard FileManager.default.fileExists(atPath: file) else {
            throw ValidationError("File not found: \(file)")
        }

        let inputURL = URL(fileURLWithPath: file)
        let originalContent = try String(contentsOf: inputURL)

        if verbose {
            print("📝 Original file size: \(originalContent.count) characters")
        }

        do {
            let migratedContent = try migrator.migrate(source: originalContent)

            if dryRun {
                print("🔍 Dry run - would make the following changes:")
                print("=" * 50)
                print(migratedContent)
                print("=" * 50)
                return
            }

            let outputPath = output ?? file
            let outputURL = URL(fileURLWithPath: outputPath)

            // Create backup if requested
            if backup && output == nil {
                let backupURL = URL(fileURLWithPath: file + ".backup")
                try FileManager.default.copyItem(at: inputURL, to: backupURL)
                if verbose {
                    print("💾 Created backup: \(backupURL.path)")
                }
            }

            try migratedContent.write(to: outputURL, atomically: true, encoding: .utf8)

            if verbose {
                print("✅ Migration completed successfully")
                print("📁 Output written to: \(outputURL.path)")
                print("📝 Migrated file size: \(migratedContent.count) characters")
            } else {
                print("✅ Successfully migrated \(file)")
            }

        } catch let error as MigrationError {
            print("❌ Migration failed: \(error.localizedDescription)")
            throw ExitCode.failure
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

private extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}
