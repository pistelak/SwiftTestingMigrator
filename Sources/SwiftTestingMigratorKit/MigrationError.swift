import Foundation

/// Errors that can occur during migration
public enum MigrationError: Error, LocalizedError, Sendable {
    case invalidSyntax(String)
    case unsupportedPattern(String)
    case setupNotSupported(String)
    case tearDownNotSupported(String)
    case fileReadError(String)
    case fileWriteError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSyntax(let message):
            return "Invalid Swift syntax: \(message)"
        case .unsupportedPattern(let pattern):
            return "Unsupported pattern that cannot be migrated: \(pattern)"
        case .setupNotSupported(let reason):
            return "setUp() method cannot be migrated: \(reason)"
        case .tearDownNotSupported(let reason):
            return "tearDown() method cannot be migrated: \(reason)"
        case .fileReadError(let path):
            return "Could not read file: \(path)"
        case .fileWriteError(let path):
            return "Could not write file: \(path)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidSyntax:
            return "Ensure the Swift file has valid syntax before migration"
        case .unsupportedPattern:
            return "This pattern requires manual migration"
        case .setupNotSupported, .tearDownNotSupported:
            return "Consider manually converting setUp/tearDown methods to init/deinit"
        case .fileReadError:
            return "Check file path and permissions"
        case .fileWriteError:
            return "Check output path and write permissions"
        }
    }
}
