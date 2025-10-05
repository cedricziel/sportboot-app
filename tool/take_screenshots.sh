#!/bin/bash

# Script to generate screenshots for all screens using integration tests
# Usage: ./tool/take_screenshots.sh

echo "🖼️  Generating screenshots for SportBoot App..."
echo ""

# Create screenshots directory
mkdir -p screenshots

# Run integration test on macOS
echo "▶️  Running automated screenshot integration test..."
flutter test integration_test/screenshot_test.dart -d macos

# Check if test succeeded
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Screenshot test failed. Please check the error output above."
    exit 1
fi

# Copy screenshots from sandboxed container to project directory
echo ""
echo "📸 Copying screenshots from container to project..."
CONTAINER_PATH="$HOME/Library/Containers/com.cedricziel.sportbootApp/Data/screenshots"
if [ -d "$CONTAINER_PATH" ]; then
    cp "$CONTAINER_PATH"/*.png screenshots/ 2>/dev/null
    echo "✅ Screenshots copied successfully!"
else
    echo "⚠️  Container path not found. Screenshots may not have been generated."
    exit 1
fi

echo ""
echo "✅ Screenshots saved to screenshots/ directory:"
echo ""
ls -lh screenshots/*.png
