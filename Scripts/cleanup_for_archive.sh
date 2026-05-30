#!/bin/bash

# Cleanup script to free up disk space before archiving
# Run this before attempting to archive in Xcode

echo "🧹 Cleaning up Xcode build artifacts..."

# Clean DerivedData for this project
echo "Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FTCHUB-*

# Clean Module Cache (can be regenerated)
echo "Cleaning Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Clean old Archives (keep only last 2)
echo "Cleaning old Archives..."
ARCHIVES_DIR=~/Library/Developer/Xcode/Archives
if [ -d "$ARCHIVES_DIR" ]; then
    cd "$ARCHIVES_DIR"
    # Keep only the 2 most recent archives
    ls -t | tail -n +3 | xargs rm -rf 2>/dev/null
fi

# Clean build folder in project
echo "Cleaning project build folder..."
cd "$(dirname "$0")/..")"
xcodebuild clean -project FTCHUB.xcodeproj -scheme FTCHUB 2>/dev/null || echo "Note: Clean command may have failed, but that's okay"

echo "✅ Cleanup complete!"
echo ""
echo "Disk space status:"
df -h / | tail -1

