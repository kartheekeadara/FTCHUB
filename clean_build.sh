#!/bin/bash

echo "🧹 Cleaning FTC Team Hub project..."

# Clean build folder
echo "1. Cleaning build folder..."
xcodebuild clean -project FTCHUB.xcodeproj -scheme FTCHUB

# Remove derived data
echo "2. Removing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FTCHUB-*

# Clean Swift Package Manager cache
echo "3. Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm

echo "✅ Clean complete! Now try building again."
echo ""
echo "Next steps:"
echo "1. Open FTCHUB.xcodeproj in Xcode"
echo "2. Product → Clean Build Folder (Cmd+Shift+K)"
echo "3. Product → Build (Cmd+B)"
