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

### Continuous Integration
SwiftLint is executed in CI using the `scripts/lint.sh` script.

## Configuration

SwiftLint is configured via `.swiftlint.yml` with:

- **Included paths**: `Sources`, `Tests`
- **Excluded paths**: `.build`, `Package.swift`, `__Snapshots__`
- **Disabled rules**: `trailing_whitespace`, `line_length`, `function_body_length`
- **Enabled opt-in rules**: `empty_count`, `force_unwrapping`, etc.

## Current Status

✅ Integrated successfully
✅ Auto-fix resolves most formatting issues
