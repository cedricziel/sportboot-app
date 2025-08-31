#!/usr/bin/env python3
"""
Validate SBF question YAML files against the JSON schema
"""

import yaml
import json
import jsonschema
from jsonschema import validate, ValidationError, Draft7Validator
import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple

def load_schema(schema_path: str) -> Dict:
    """Load JSON schema from file"""
    with open(schema_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_yaml(yaml_path: str) -> Dict:
    """Load YAML file"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def validate_yaml_file(yaml_path: str, schema: Dict) -> Tuple[bool, List[str]]:
    """
    Validate a YAML file against the schema
    Returns: (is_valid, list_of_errors)
    """
    errors = []
    
    try:
        data = load_yaml(yaml_path)
        
        # Create a validator to get all errors at once
        validator = Draft7Validator(schema)
        
        # Collect all validation errors
        for error in validator.iter_errors(data):
            error_path = '.'.join(str(x) for x in error.path)
            errors.append(f"  - {error_path}: {error.message}")
        
        # Additional custom validations
        if 'questions' in data:
            for idx, question in enumerate(data['questions']):
                # Check that exactly one answer is marked as correct
                if 'options' in question:
                    correct_count = 0
                    option_texts = []
                    
                    for opt_idx, option in enumerate(question['options']):
                        if isinstance(option, dict):
                            if option.get('isCorrect', False):
                                correct_count += 1
                            # Check for duplicate answer texts
                            text = option.get('text', '')
                            if text in option_texts:
                                errors.append(
                                    f"  - questions[{idx}].options[{opt_idx}]: Duplicate answer text found"
                                )
                            option_texts.append(text)
                    
                    if correct_count == 0:
                        errors.append(
                            f"  - questions[{idx}].options: No correct answer specified"
                        )
                    elif correct_count > 1:
                        errors.append(
                            f"  - questions[{idx}].options: Multiple correct answers specified ({correct_count})"
                        )
                
                # Validate asset paths exist
                if 'assets' in question:
                    for asset in question['assets']:
                        asset_path = os.path.join(os.path.dirname(yaml_path), asset)
                        if not os.path.exists(asset_path):
                            errors.append(
                                f"  - questions[{idx}].assets: Asset file not found: {asset}"
                            )
        
        if not errors:
            # Final validation with jsonschema
            validate(instance=data, schema=schema)
            
        return (len(errors) == 0, errors)
        
    except ValidationError as e:
        errors.append(f"  - Schema validation error: {e.message}")
        return (False, errors)
    except Exception as e:
        errors.append(f"  - Error loading/parsing file: {str(e)}")
        return (False, errors)

def print_validation_report(results: Dict[str, Tuple[bool, List[str]]]):
    """Print a formatted validation report"""
    print("\n" + "="*60)
    print("VALIDATION REPORT")
    print("="*60)
    
    total_files = len(results)
    valid_files = sum(1 for is_valid, _ in results.values() if is_valid)
    invalid_files = total_files - valid_files
    
    # Print summary
    print(f"\nTotal files checked: {total_files}")
    print(f"✅ Valid files: {valid_files}")
    if invalid_files > 0:
        print(f"❌ Invalid files: {invalid_files}")
    
    # Print details for each file
    print("\nFile Details:")
    print("-"*60)
    
    for filepath, (is_valid, errors) in results.items():
        filename = os.path.basename(filepath)
        if is_valid:
            print(f"✅ {filename}: VALID")
        else:
            print(f"❌ {filename}: INVALID")
            for error in errors:
                print(error)
    
    print("="*60)
    
    return invalid_files == 0

def main():
    """Main validation function"""
    # Paths
    data_dir = Path(".data/courses/sbf-see")
    schema_path = data_dir / "schema.json"
    
    # Check if schema exists
    if not schema_path.exists():
        print(f"Error: Schema file not found at {schema_path}")
        sys.exit(1)
    
    # Load schema
    try:
        schema = load_schema(str(schema_path))
        print(f"Loaded schema from {schema_path}")
    except Exception as e:
        print(f"Error loading schema: {e}")
        sys.exit(1)
    
    # Find all YAML files
    yaml_files = list(data_dir.glob("*.yaml")) + list(data_dir.glob("*.yml"))
    
    if not yaml_files:
        print(f"No YAML files found in {data_dir}")
        sys.exit(1)
    
    print(f"Found {len(yaml_files)} YAML file(s) to validate")
    
    # Validate each file
    results = {}
    for yaml_file in yaml_files:
        print(f"Validating {yaml_file.name}...")
        is_valid, errors = validate_yaml_file(str(yaml_file), schema)
        results[str(yaml_file)] = (is_valid, errors)
    
    # Print report
    all_valid = print_validation_report(results)
    
    # Exit with appropriate code
    sys.exit(0 if all_valid else 1)

if __name__ == "__main__":
    main()