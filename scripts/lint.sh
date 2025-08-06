#!/bin/bash

# SwiftLint script for Swift Testing Migrator project

set -e

echo "🔍 Running SwiftLint..."

# Check if --fix argument is provided
if [[ "$1" == "--fix" ]]; then
    echo "🔧 Auto-fixing violations where possible..."
    swiftlint --fix --format
    echo "✅ Auto-fix completed!"
fi

# Run linting
echo "📋 Linting results:"
swiftlint

echo "🏁 SwiftLint completed successfully!"