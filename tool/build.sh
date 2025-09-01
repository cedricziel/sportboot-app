#!/bin/bash

# Build script for scraping and processing SBF questions

set -e

echo "🚀 Starting SBF Question Build Process"
echo ""

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart is not installed"
    exit 1
fi

# Run the Dart scraper
echo "📚 Running question scraper..."
dart run tool/scrape_questions.dart

# Copy processed data to assets
echo ""
echo "📦 Copying data to Flutter assets..."

# Create target directories if they don't exist
mkdir -p assets/data/catalogs
mkdir -p assets/data/courses

# Copy catalog files
if [ -d ".data/catalogs" ]; then
    cp -r .data/catalogs/* assets/data/catalogs/ 2>/dev/null || true
    echo "   ✓ Copied catalog files"
fi

# Copy course files
if [ -d ".data/courses" ]; then
    for course_dir in .data/courses/*/; do
        if [ -d "$course_dir" ]; then
            course_name=$(basename "$course_dir")
            mkdir -p "assets/data/courses/$course_name"
            cp -r "$course_dir"* "assets/data/courses/$course_name/" 2>/dev/null || true
            echo "   ✓ Copied course: $course_name"
        fi
    done
fi

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "You can now run the Flutter app with:"
echo "  flutter run"