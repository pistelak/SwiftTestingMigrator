# SwiftLint Integration

SwiftLint has been integrated into the Swift Testing Migrator project to ensure code quality and consistency.

## Usage

### Via Script (Recommended)
```bash
# Run linting
./scripts/lint.sh

# Run linting with auto-fix
./scripts/lint.sh --fix
```

### Direct SwiftLint Commands
```bash
# Basic linting
swiftlint

# Auto-fix issues
swiftlint --fix

# Lint specific directory
swiftlint lint Sources
```

### During Build
SwiftLint runs automatically during `swift build` via the build tool plugin.

## Configuration

SwiftLint is configured via `.swiftlint.yml` with:

- **Included paths**: `Sources`, `Tests`
- **Excluded paths**: `.build`, `Package.swift`, `__Snapshots__`
- **Disabled rules**: `trailing_whitespace`, `line_length`, `function_body_length`
- **Enabled opt-in rules**: `empty_count`, `force_unwrapping`, etc.

## Current Status

✅ Integrated successfully  
✅ Auto-fix resolves most formatting issues  
⚠️ 9 remaining violations (mostly force unwrapping warnings)

The remaining violations are mostly force unwrapping in SwiftSyntax code, which are acceptable for AST manipulation.