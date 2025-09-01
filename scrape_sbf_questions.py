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

def parse_question_and_answers(p_element, ol_element, question_num: int, category: str) -> Optional[Dict]:
    """Parse a question from a paragraph and its answers from the following ordered list"""
    try:
        # Extract question text from the paragraph
        # Need to handle nested elements like images
        question_parts = []
        
        # Get direct text content
        for child in p_element.children:
            if isinstance(child, str):
                text = child.strip()
                if text:
                    question_parts.append(text)
            elif child.name == 'p' and 'picture' in child.get('class', []):
                # This is an embedded image - add placeholder or description
                img = child.find('img')
                if img and img.get('alt'):
                    question_parts.append(f"[{img.get('alt')}]")
        
        question_text = ' '.join(question_parts)
        
        # Remove the question number from the beginning
        question_text = re.sub(r'^\d+\.\s*', '', question_text).strip()
        
        if not question_text:
            return None
        
        # Check for associated images
        assets = []
        imgs = p_element.find_all('img')
        for img in imgs:
            src = img.get('src', '')
            if src:
                # Clean filename - remove query parameters
                filename = os.path.basename(src.split('?')[0])
                if filename:
                    assets.append(f"assets/{filename}")
        
        # Parse answer options from the ordered list
        answer_lis = ol_element.find_all('li', recursive=False)
        if not answer_lis:
            return None
        
        # Convert options to objects with isCorrect flag
        # First option (a) is always correct according to the note on the page
        answer_objects = []
        for idx, li in enumerate(answer_lis):
            option_text = li.get_text().strip()
            if option_text:
                answer_objects.append({
                    "text": option_text,
                    "isCorrect": idx == 0  # First option is always correct
                })
        
        if not answer_objects:
            return None
        
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
        
        # Find the main content area
        content = soup.find('div', id='content')
        if not content:
            content = soup
        
        # Find all paragraphs that contain questions
        # Questions are in <p> tags and start with a number
        all_paragraphs = content.find_all('p')
        
        question_num = 0
        for i, p in enumerate(all_paragraphs):
            # Get the text content to check if it's a question
            text = p.get_text().strip()
            
            # Skip empty paragraphs and separator lines
            if not text or p.get('class') == ['line'] or p.get('class') == ['wsv-red']:
                continue
            
            # Check if this paragraph starts with a question number
            if re.match(r'^\d+\.\s+\w', text):
                # This is likely a question
                # Find the next ordered list with answer options
                next_sibling = p.find_next_sibling()
                
                # Handle cases where there might be embedded images
                while next_sibling and next_sibling.name == 'p' and 'picture' in next_sibling.get('class', []):
                    # This is an embedded image, skip to next
                    next_sibling = next_sibling.find_next_sibling()
                
                if next_sibling and next_sibling.name == 'ol' and 'elwisOL-lowerLiteral' in next_sibling.get('class', []):
                    # Found the answer list
                    question_num += 1
                    question_data = parse_question_and_answers(p, next_sibling, question_num, category)
                    if question_data:
                        questions.append(question_data)
                        print(f"  Parsed question {question_data['number']}: {question_data['question'][:50]}...")
        
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
                # Skip non-question related images (logos, icons, etc.)
                if filename and filename not in downloaded_assets and 'Schallsignal' in src:
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