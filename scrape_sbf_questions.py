#!/usr/bin/env python3
"""
Script to scrape SBF-See questions from ELWIS website and save as YAML
"""

import requests
from bs4 import BeautifulSoup
import yaml
import re
import os
from typing import Dict, List, Optional, Tuple
from urllib.parse import urljoin, urlparse
import time
import json
try:
    from jsonschema import validate, ValidationError, Draft7Validator
    JSONSCHEMA_AVAILABLE = True
except ImportError:
    JSONSCHEMA_AVAILABLE = False
    print("Warning: jsonschema not installed. Skipping validation.")

BASE_URL = "https://www.elwis.de"
QUESTIONS_URLS = {
    "basisfragen": "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-See/Basisfragen/Basisfragen-node.html",
    "spezifische-see": "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-See/Spezifische-Fragen-See/Spezifische-Fragen-See-node.html"
}

OUTPUT_DIR = ".data/courses/sbf-see"
ASSETS_DIR = os.path.join(OUTPUT_DIR, "assets")

def ensure_directories():
    """Create necessary directories if they don't exist"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

def download_asset(url: str, filename: str) -> str:
    """Download an asset and return the local path"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        filepath = os.path.join(ASSETS_DIR, filename)
        with open(filepath, 'wb') as f:
            f.write(response.content)
        
        return f"assets/{filename}"
    except Exception as e:
        print(f"Error downloading asset {url}: {e}")
        return ""

def parse_question_from_ol(ol_element, question_num: int, category: str) -> Optional[Dict]:
    """Parse a single question from an ordered list element"""
    try:
        # Get all list items
        lis = ol_element.find_all('li', recursive=False)
        if len(lis) < 2:  # Need at least question and one answer
            return None
        
        # First li is the question
        question_text = lis[0].get_text().strip()
        
        # Check for associated images in the question
        assets = []
        imgs = lis[0].find_all('img')
        for img in imgs:
            src = img.get('src', '')
            if src:
                # Clean filename - remove query parameters
                filename = os.path.basename(src.split('?')[0])
                if filename:
                    assets.append(f"assets/{filename}")
        
        # Rest are answer options - get the nested ol
        answer_ol = lis[1].find('ol')
        if not answer_ol:
            # Sometimes answers are directly in li elements
            options = []
            for i in range(1, len(lis)):
                option_text = lis[i].get_text().strip()
                if option_text:
                    options.append(option_text)
        else:
            # Parse nested ol for answer options
            answer_lis = answer_ol.find_all('li', recursive=False)
            options = [li.get_text().strip() for li in answer_lis if li.get_text().strip()]
        
        if not options:
            return None
        
        # Convert options to objects with isCorrect flag
        # First option is correct (option 'a' in the original format)
        answer_objects = []
        for idx, option_text in enumerate(options):
            answer_objects.append({
                "text": option_text,
                "isCorrect": idx == 0  # First option is always correct
            })
        
        return {
            "id": f"sbf-see-{category[:3]}-{question_num:03d}",
            "number": question_num,
            "question": question_text,
            "options": answer_objects,
            "category": category,
            "assets": assets
        }
    except Exception as e:
        print(f"    Error parsing question {question_num}: {e}")
        return None

def scrape_questions_page(url: str, category: str) -> List[Dict]:
    """Scrape all questions from a single page"""
    print(f"Scraping {category} from {url}")
    
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        questions = []
        
        # Find all ordered lists - these contain the questions
        all_ols = soup.find_all('ol')
        
        # Filter to find the main question lists
        # The main pattern is that questions are in numbered OLs
        question_num = 1
        
        for ol in all_ols:
            # Skip nested OLs (answer options)
            parent = ol.parent
            if parent and parent.name == 'li':
                continue
                
            # Try to parse as a question
            question_data = parse_question_from_ol(ol, question_num, category)
            if question_data:
                questions.append(question_data)
                print(f"  Parsed question {question_data['number']}: {question_data['question'][:50]}...")
                question_num += 1
        
        # Download any images found
        images = soup.find_all('img')
        downloaded_assets = set()
        for img in images:
            src = img.get('src', '')
            if src and not src.startswith('http'):
                src = urljoin(url, src)
            if src:
                # Clean filename - remove query parameters
                filename = os.path.basename(urlparse(src).path)
                if filename and filename not in downloaded_assets:
                    local_path = download_asset(src, filename)
                    if local_path:
                        downloaded_assets.add(filename)
                        print(f"  Downloaded asset: {filename}")
        
        return questions
        
    except Exception as e:
        print(f"Error scraping {url}: {e}")
        return []

def validate_yaml_data(yaml_data: Dict, schema_path: str) -> Tuple[bool, List[str]]:
    """Validate YAML data against schema"""
    if not JSONSCHEMA_AVAILABLE:
        return (True, ["Validation skipped - jsonschema not installed"])
    
    if not os.path.exists(schema_path):
        return (True, ["Schema file not found - skipping validation"])
    
    try:
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        
        validator = Draft7Validator(schema)
        errors = []
        
        for error in validator.iter_errors(yaml_data):
            error_path = '.'.join(str(x) for x in error.path)
            errors.append(f"  {error_path}: {error.message}")
        
        if errors:
            return (False, errors)
        
        # Additional validation
        if 'questions' in yaml_data:
            for idx, question in enumerate(yaml_data['questions']):
                # Check that exactly one answer is marked as correct
                if 'options' in question:
                    correct_count = sum(1 for opt in question['options'] if opt.get('isCorrect', False))
                    if correct_count == 0:
                        errors.append(f"  questions[{idx}]: No correct answer specified")
                    elif correct_count > 1:
                        errors.append(f"  questions[{idx}]: Multiple correct answers specified ({correct_count})")
        
        return (len(errors) == 0, errors)
        
    except Exception as e:
        return (False, [f"Validation error: {str(e)}"])

def save_questions_to_yaml(questions: List[Dict], filename: str):
    """Save questions to a YAML file"""
    filepath = os.path.join(OUTPUT_DIR, filename)
    
    # Structure for YAML with schema reference
    yaml_data = {
        "$schema": "./schema.json",
        "course": "SBF-See",
        "version": "2024",
        "source": "ELWIS",
        "questions": questions
    }
    
    with open(filepath, 'w', encoding='utf-8') as f:
        yaml.dump(yaml_data, f, allow_unicode=True, default_flow_style=False, sort_keys=False)
    
    print(f"Saved {len(questions)} questions to {filepath}")
    
    # Validate if schema exists
    schema_path = os.path.join(OUTPUT_DIR, "schema.json")
    is_valid, errors = validate_yaml_data(yaml_data, schema_path)
    
    if is_valid:
        print(f"  ✅ Validation: PASSED")
    else:
        print(f"  ❌ Validation: FAILED")
        for error in errors[:5]:  # Show first 5 errors
            print(f"    {error}")
        if len(errors) > 5:
            print(f"    ... and {len(errors) - 5} more errors")

def main():
    """Main function to orchestrate the scraping"""
    ensure_directories()
    
    all_questions = []
    
    for category, url in QUESTIONS_URLS.items():
        questions = scrape_questions_page(url, category)
        all_questions.extend(questions)
        
        # Save category-specific file
        if questions:
            save_questions_to_yaml(questions, f"{category}.yaml")
        
        # Be polite to the server
        time.sleep(2)
    
    # Save all questions in one file
    if all_questions:
        save_questions_to_yaml(all_questions, "all_questions.yaml")
    
    print(f"\nTotal questions scraped: {len(all_questions)}")
    print(f"Output directory: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()