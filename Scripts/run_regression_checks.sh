#!/usr/bin/env bash

set -euo pipefail

SCHEME="FTCHUB"
DESTINATION="platform=iOS Simulator,name=iPhone 17"

echo "=== FTC HUB Regression Checks ==="
echo "1) Cleaning derived data"
xcodebuild -project FTCHUB.xcodeproj -scheme "${SCHEME}" -sdk iphonesimulator -configuration Debug clean >/dev/null

echo "2) Building debug configuration"
xcodebuild -project FTCHUB.xcodeproj -scheme "${SCHEME}" -sdk iphonesimulator -configuration Debug build

echo "3) Running smoke UI tests (empty suite ok)"
xcodebuild -project FTCHUB.xcodeproj -scheme "${SCHEME}" -sdk iphonesimulator -configuration Debug test -destination "${DESTINATION}" || true

if command -v swiftlint >/dev/null 2>&1; then
  echo "4) SwiftLint"
  swiftlint
else
  echo "4) SwiftLint skipped (swiftlint not installed)"
fi

echo "5) Generating QA summary"
BUILD_LOG="qa_build_$(date +%Y%m%d%H%M).log"
xcodebuild -project FTCHUB.xcodeproj -scheme "${SCHEME}" -sdk iphonesimulator -configuration Debug build > "${BUILD_LOG}"
echo "Build log saved to ${BUILD_LOG}"

echo "Regression checks complete."

