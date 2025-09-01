# Makefile for scraping boat license questions

# Variables
PYTHON = python3
VENV = venv
DATA_SOURCE = .data/courses
DATA_TARGET = assets/data/courses

.PHONY: help scrape scrape-sbf-see copy-data clean

# Default target - show help
help:
	@echo "Available targets:"
	@echo "  scrape       - Run all course scrapers"
	@echo "  copy-data    - Copy scraped data to app assets"
	@echo "  clean        - Remove temporary files"

# Main scrape target - calls all course scrapers
scrape: scrape-sbf-see
	@echo "✓ All scrapers completed"

# SBF-See (Sportbootführerschein See) scraper
scrape-sbf-see:
	@echo "Scraping SBF-See questions..."
	@source $(VENV)/bin/activate && $(PYTHON) scrape_sbf_questions.py

# Future scrapers can be added here:
# scrape-sbf-binnen:
#	@echo "Scraping SBF-Binnen questions..."
#	@source $(VENV)/bin/activate && $(PYTHON) scrape_sbf_binnen.py

# Copy all scraped data to app folder
copy-data:
	@echo "Copying data to Flutter assets..."
	@cp -r $(DATA_SOURCE)/* $(DATA_TARGET)/
	@echo "✓ Data copied to $(DATA_TARGET)"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✓ Cleaned"