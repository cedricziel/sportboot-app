# Makefile for building SBF question data

# Variables
DATA_SOURCE = .data
DATA_TARGET = assets/data
CACHE_DIR = .cache

.PHONY: help build scrape-dart scrape-python copy-data clean clean-cache

# Default target - show help
help:
	@echo "Available targets:"
	@echo "  build        - Run Dart scraper and copy data (recommended)"
	@echo "  scrape-dart  - Run Dart question scraper"
	@echo "  scrape-python- Run Python scraper (legacy)"
	@echo "  copy-data    - Copy scraped data to app assets"
	@echo "  clean        - Remove temporary files"
	@echo "  clean-cache  - Remove cached HTML files"

# Main build target using Dart
build:
	@./tool/build.sh

# Run Dart scraper directly
scrape-dart:
	@echo "Running Dart scraper..."
	@dart run tool/scrape_questions.dart

# Legacy Python scraper (kept for reference)
scrape-python:
	@echo "Running Python scraper..."
	@if [ -d "$(VENV)" ]; then \
		source $(VENV)/bin/activate && python3 scrape_sbf_questions.py; \
	else \
		python3 scrape_sbf_questions.py; \
	fi

# Copy all scraped data to app folder
copy-data:
	@echo "Copying data to Flutter assets..."
	@mkdir -p $(DATA_TARGET)/catalogs $(DATA_TARGET)/courses
	@if [ -d "$(DATA_SOURCE)/catalogs" ]; then \
		cp -r $(DATA_SOURCE)/catalogs/* $(DATA_TARGET)/catalogs/ 2>/dev/null || true; \
	fi
	@if [ -d "$(DATA_SOURCE)/courses" ]; then \
		cp -r $(DATA_SOURCE)/courses/* $(DATA_TARGET)/courses/ 2>/dev/null || true; \
	fi
	@echo "✓ Data copied to $(DATA_TARGET)"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -rf $(DATA_SOURCE) 2>/dev/null || true
	@echo "✓ Cleaned"

# Clean cache directory
clean-cache:
	@echo "Cleaning cache..."
	@rm -rf $(CACHE_DIR) 2>/dev/null || true
	@echo "✓ Cache cleaned"