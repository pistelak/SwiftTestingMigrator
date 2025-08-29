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
        SwiftTestingMigrator --file Tests.swift --output MigratedTests.swift
      """
    )

    @Option(
        name: .shortAndLong,
        help: "Path to the Swift test file to migrate"
    )
    var file: String?

    @Option(
        name: [.long],
        help: "Path to a folder containing Swift test files to migrate"
    )
    var folder: String?

    @Option(
        name: .shortAndLong,
        help: "Output file path (defaults to overwriting input file)"
    )
    var output: String?

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

        if let folder {
            try processFolder(at: folder, using: migrator)
            return
        }

        guard let file else {
            throw ValidationError("Please provide either --file or --folder")
        }

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

    private func processFolder(at path: String, using migrator: TestMigrator) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ValidationError("Folder not found: \(path)")
        }

        let folderURL = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            throw ValidationError("Unable to read folder: \(path)")
        }

        var converted: [String] = []
        var already: [String] = []
        var unsupported: [(String, String)] = []

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            if verbose {
                print("🔍 Reading file: \(fileURL.path)")
            }

            let original = try String(contentsOf: fileURL)
            do {
                let migrated = try migrator.migrate(source: original)
                if migrated == original {
                    already.append(fileURL.path)
                    if verbose {
                        print("⏭️ Already migrated: \(fileURL.path)")
                    }
                } else {
                    if backup {
                        let backupURL = fileURL.appendingPathExtension("backup")
                        try? FileManager.default.copyItem(at: fileURL, to: backupURL)
                    }
                    try migrated.write(to: fileURL, atomically: true, encoding: .utf8)
                    converted.append(fileURL.path)
                    if verbose {
                        print("✅ Migrated: \(fileURL.path)")
                    }
                }
            } catch let error as MigrationError {
                unsupported.append((fileURL.path, error.localizedDescription))
                if verbose {
                    print("❌ Skipped: \(fileURL.path) (\(error.localizedDescription))")
                }
            } catch {
                unsupported.append((fileURL.path, error.localizedDescription))
                if verbose {
                    print("❌ Skipped: \(fileURL.path) (\(error.localizedDescription))")
                }
            }
        }

        print("Migration results:")
        for file in converted {
            print("  ✅ Converted: \(file)")
        }
        for file in already {
            print("  ⏭️ Already migrated: \(file)")
        }
        for (file, reason) in unsupported {
            print("  ❌ Unsupported: \(file) (\(reason))")
        }
        print("\nSummary: \(converted.count) converted, \(already.count) already migrated, \(unsupported.count) unsupported")
    }
}

private extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}
