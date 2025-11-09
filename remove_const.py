#!/usr/bin/env python3
"""
Remove 'const' keyword before Text widgets that use AppLocalizations
"""

import os
import re
from pathlib import Path

def remove_const_from_app_localizations(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Remove 'const ' before Text(AppLocalizations
    content = re.sub(r'const\s+(Text\(AppLocalizations\.of\(context\)!\.)', r'\1', content)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    dart_files = list(Path('lib/features').rglob('*.dart'))
    files_modified = 0
    
    for file_path in dart_files:
        if remove_const_from_app_localizations(str(file_path)):
            files_modified += 1
            print(f"Fixed: {file_path}")
    
    print(f"\nTotal files modified: {files_modified}")

if __name__ == '__main__':
    main()
