#!/bin/bash

# Script to increment build number in pubspec.yaml

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')

# Split version into name and build number
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
CURRENT_BUILD=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Increment build number
NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_VERSION="${VERSION_NAME}+${NEW_BUILD}"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
else
    # Linux
    sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
fi

echo -e "${GREEN}✓${NC} Version updated: ${YELLOW}$CURRENT_VERSION${NC} → ${GREEN}$NEW_VERSION${NC}"

# Optional: Show git status
if [ -d .git ]; then
    echo ""
    echo "Git status:"
    git diff pubspec.yaml | grep "^[+-]version:" || true
fi

# Optional: Commit the change (uncomment if desired)
# if [ -d .git ]; then
#     git add pubspec.yaml
#     git commit -m "build: bump version to $NEW_VERSION"
#     echo -e "${GREEN}✓${NC} Changes committed"
# fi