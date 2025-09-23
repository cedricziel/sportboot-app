# Makefile for building SBF question data

# Variables
DATA_SOURCE = .data
DATA_TARGET = assets/data
CACHE_DIR = .cache

.PHONY: help build scrape copy-data clean clean-cache logo splash icons bump build-ios build-testflight

# Default target - show help
help:
	@echo "Available targets:"
	@echo "  build        - Run Dart scraper and copy data (recommended)"
	@echo "  scrape       - Run Dart question scraper"
	@echo "  copy-data    - Copy scraped data to app assets"
	@echo "  logo         - Generate app logo images"
	@echo "  icons        - Generate app icons for iOS and macOS"
	@echo "  splash       - Generate native splash screens (requires logo)"
	@echo "  bump         - Increment build number in pubspec.yaml"
	@echo "  build-ios    - Build iOS app for release (auto-increments build number)"
	@echo "  build-testflight - Build and prepare for TestFlight upload"
	@echo "  clean        - Remove temporary files and build artifacts"
	@echo "  clean-cache  - Remove cached HTML files"

# Main build target using Dart
build:
	@./tool/build.sh

# Run Dart scraper directly
scrape:
	@echo "Running Dart scraper..."
	@dart run tool/scrape_questions.dart

# Copy course data to app folder (catalogs not needed)
copy-data:
	@echo "Copying course data to Flutter assets..."
	@mkdir -p $(DATA_TARGET)/courses
	@if [ -d "$(DATA_SOURCE)/courses" ]; then \
		cp -r $(DATA_SOURCE)/courses/* $(DATA_TARGET)/courses/ 2>/dev/null || true; \
	fi
	@echo "✓ Course data copied to $(DATA_TARGET)"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@rm -rf $(DATA_SOURCE) 2>/dev/null || true
	@echo "✓ Cleaned"

# Clean cache directory
clean-cache:
	@echo "Cleaning cache..."
	@rm -rf $(CACHE_DIR) 2>/dev/null || true
	@echo "✓ Cache cleaned"

# Generate logo images
logo:
	@echo "Generating logo images..."
	@if ! command -v python3 >/dev/null 2>&1; then \
		echo "Error: Python 3 is required to generate logos"; \
		exit 1; \
	fi
	@if [ ! -d "venv" ]; then \
		echo "Creating Python virtual environment..."; \
		python3 -m venv venv; \
	fi
	@echo "Installing dependencies..."
	@./venv/bin/pip install -q Pillow
	@echo "Generating logos..."
	@./venv/bin/python tool/generate_logo.py
	@echo "✓ Logo images generated"

# Generate native splash screens
splash: logo
	@echo "Generating native splash screens..."
	@flutter pub get
	@dart run flutter_native_splash:create
	@echo "✓ Splash screens generated"

# Generate app icons for iOS and macOS
icons:
	@echo "Generating app icons for iOS and macOS..."
	@flutter pub get
	@dart run flutter_launcher_icons
	@echo "✓ App icons generated for iOS and macOS"

# Increment build number
bump:
	@./tool/bump_build.sh

# Build iOS app for release
build-ios: bump
	@echo "Building iOS app for release..."
	@flutter clean
	@flutter pub get
	@flutter build ios --release
	@echo "✓ iOS app built successfully"
	@echo ""
	@echo "Next steps:"
	@echo "1. Open ios/Runner.xcworkspace in Xcode"
	@echo "2. Select 'Any iOS Device' as the target"
	@echo "3. Product > Archive"
	@echo "4. Distribute App > TestFlight & App Store"

# Build for TestFlight (includes everything needed)
build-testflight: icons splash bump
	@echo "Preparing build for TestFlight..."
	@flutter clean
	@flutter pub get
	@flutter build ios --release
	@echo "✓ Build prepared for TestFlight"
	@echo ""
	@echo "To upload to TestFlight:"
	@echo "1. Open ios/Runner.xcworkspace in Xcode"
	@echo "2. Select 'Any iOS Device' as the target"
	@echo "3. Product > Archive"
	@echo "4. In Organizer: Distribute App > TestFlight & App Store"
	@echo "5. Follow the upload wizard"
	@echo ""
	@echo "Alternative: Use Transporter app for direct upload"