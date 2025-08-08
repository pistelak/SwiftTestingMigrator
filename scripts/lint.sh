#!/bin/bash

# SwiftLint script for Swift Testing Migrator project

set -e

echo "🔍 Running SwiftLint..."

# Resolve SwiftLint command, installing if necessary
if command -v swiftlint >/dev/null 2>&1; then
    SWIFTLINT_CMD="swiftlint"
else
    echo "ℹ️  SwiftLint not found, attempting installation..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install swiftlint >/dev/null
        SWIFTLINT_CMD="swiftlint"
    else
        TMP_DIR=$(mktemp -d)
        curl -Ls https://github.com/realm/SwiftLint/releases/latest/download/swiftlint_linux.zip -o "$TMP_DIR/swiftlint.zip"
        unzip -q "$TMP_DIR/swiftlint.zip" -d "$TMP_DIR"
        SWIFTLINT_CMD="$TMP_DIR/swiftlint"
        chmod +x "$SWIFTLINT_CMD"
        export PATH="$TMP_DIR:$PATH"
    fi
    echo "✅ SwiftLint installed"
fi

# Check if --fix argument is provided
if [[ "$1" == "--fix" ]]; then
    echo "🔧 Auto-fixing violations where possible..."
    "$SWIFTLINT_CMD" --fix --format
    echo "✅ Auto-fix completed!"
fi

# Run linting
echo "📋 Linting results:"
"$SWIFTLINT_CMD"

echo "🏁 SwiftLint completed successfully!"
