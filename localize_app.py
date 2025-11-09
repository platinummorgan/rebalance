#!/usr/bin/env python3
"""
Automated localization script for Flutter app.
Replaces hardcoded strings with AppLocalizations calls.
"""

import os
import re
import json
from pathlib import Path

# Load ARB file to get available translations
def load_arb_keys(arb_path='lib/l10n/app_en.arb'):
    with open(arb_path, 'r', encoding='utf-8') as f:
        arb_data = json.load(f)
    # Filter out metadata keys (starting with @@) and non-string values
    return {k: v for k, v in arb_data.items() if not k.startswith('@@') and isinstance(v, str)}

# Common string patterns to replace
def create_replacements(arb_keys):
    replacements = []
    for key, value in arb_keys.items():
        # Skip strings with placeholders for now
        if '{' in value:
            continue
        
        # Escape special regex characters in the value
        escaped_value = re.escape(value)
        
        # Pattern: Text('value') or Text("value")
        pattern1 = rf"Text\(['\"]({escaped_value})['\"]\)"
        replacement1 = f"Text(AppLocalizations.of(context)!.{key})"
        replacements.append((pattern1, replacement1, value))
        
        # Pattern: const Text('value') or const Text("value") - REMOVE const
        pattern2 = rf"const\s+Text\(['\"]({escaped_value})['\"]\)"
        replacement2 = f"Text(AppLocalizations.of(context)!.{key})"
        replacements.append((pattern2, replacement2, value))
        
        # Pattern: title: 'value' or title: "value"
        pattern3 = rf"title:\s*['\"]({escaped_value})['\"]\)"
        replacement3 = f"title: AppLocalizations.of(context)!.{key})"
        replacements.append((pattern3, replacement3, value))
        
        # Pattern: title: const Text('value') - REMOVE const
        pattern4 = rf"title:\s*const\s+Text\(['\"]({escaped_value})['\"]\)"
        replacement4 = f"title: Text(AppLocalizations.of(context)!.{key})"
        replacements.append((pattern4, replacement4, value))
        
        # Pattern: child: const Text('value') - REMOVE const
        pattern5 = rf"child:\s*const\s+Text\(['\"]({escaped_value})['\"]\)"
        replacement5 = f"child: Text(AppLocalizations.of(context)!.{key})"
        replacements.append((pattern5, replacement5, value))
        
        # Pattern: label: const Text('value') - REMOVE const
        pattern6 = rf"label:\s*const\s+Text\(['\"]({escaped_value})['\"]\)"
        replacement6 = f"label: Text(AppLocalizations.of(context)!.{key})"
        replacements.append((pattern6, replacement6, value))
    
    return replacements

# Check if file already has AppLocalizations import
def has_localizations_import(content):
    return "import '../generated/app_localizations.dart'" in content or \
           "import '../../generated/app_localizations.dart'" in content or \
           "import 'generated/app_localizations.dart'" in content

# Add AppLocalizations import to file
def add_import(content, file_path):
    # Determine correct import path based on file location
    depth = len(Path(file_path).relative_to('lib').parts) - 1
    if depth == 0:
        import_path = "import 'generated/app_localizations.dart';"
    elif depth == 1:
        import_path = "import '../generated/app_localizations.dart';"
    else:
        import_path = "import '../../generated/app_localizations.dart';"
    
    # Find last import statement
    lines = content.split('\n')
    last_import_idx = 0
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_idx = i
    
    # Insert after last import
    lines.insert(last_import_idx + 1, import_path)
    return '\n'.join(lines)

# Process a single Dart file
def process_file(file_path, replacements, dry_run=True):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    changes_made = []
    
    # Apply replacements
    for pattern, replacement, original_text in replacements:
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            changes_made.append(original_text)
    
    # Add import if needed and changes were made
    if changes_made and not has_localizations_import(content):
        content = add_import(content, file_path)
    
    # Write back if not dry run and changes were made
    if not dry_run and content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return len(changes_made), changes_made
    elif dry_run and content != original_content:
        return len(changes_made), changes_made
    
    return 0, []

# Main execution
def main():
    print("🌍 Flutter Localization Automation Tool\n")
    
    # Load ARB keys
    print("📖 Loading translation keys from ARB file...")
    arb_keys = load_arb_keys()
    print(f"   Found {len(arb_keys)} translation keys\n")
    
    # Create replacement patterns
    print("🔨 Creating replacement patterns...")
    replacements = create_replacements(arb_keys)
    print(f"   Generated {len(replacements)} replacement patterns\n")
    
    # Find all Dart files in lib/features
    dart_files = list(Path('lib/features').rglob('*.dart'))
    print(f"🔍 Found {len(dart_files)} Dart files to process\n")
    
    # Ask user if they want to proceed
    print("This will:")
    print("  1. Replace hardcoded strings with AppLocalizations calls")
    print("  2. Add necessary imports")
    print("  3. Process all files in lib/features/")
    print("\nWould you like to:")
    print("  1. Dry run (preview changes)")
    print("  2. Apply changes")
    print("  3. Exit")
    
    choice = input("\nEnter choice (1/2/3): ").strip()
    
    if choice == '3':
        print("Exiting...")
        return
    
    dry_run = choice == '1'
    
    print(f"\n{'🔍 DRY RUN - No files will be modified' if dry_run else '✍️  APPLYING CHANGES'}\n")
    
    total_changes = 0
    files_modified = 0
    
    for file_path in dart_files:
        changes, changed_strings = process_file(str(file_path), replacements, dry_run)
        if changes > 0:
            files_modified += 1
            total_changes += changes
            print(f"{'[DRY RUN]' if dry_run else '[MODIFIED]'} {file_path}")
            for s in changed_strings[:5]:  # Show first 5 changes
                print(f"   - '{s}'")
            if len(changed_strings) > 5:
                print(f"   ... and {len(changed_strings) - 5} more")
            print()
    
    print(f"\n{'📊 Summary (DRY RUN)' if dry_run else '✅ Complete!'}")
    print(f"   Files modified: {files_modified}")
    print(f"   Total replacements: {total_changes}")
    
    if dry_run:
        print("\nRun again and choose option 2 to apply changes.")

if __name__ == '__main__':
    main()
