#!/usr/bin/env python3
"""
Script to identify all remaining NumberFormat.currency and NumberFormat.compact
instances that need to be replaced with CurrencyFormatter calls.
"""

import re
from pathlib import Path

# Files to process
FILES_TO_CHECK = [
    "lib/features/dashboard/dashboard_screen.dart",
    "lib/features/accounts/accounts_screen.dart",
    "lib/features/liabilities/liabilities_screen.dart",
    "lib/features/rebalancing/rebalancing_plan_screen.dart",
    "lib/features/reports/reports_screen.dart",
    "lib/features/debt_optimizer/debt_optimizer_screen.dart",
    "lib/features/scenario_engine/scenario_engine_screen.dart",
    "lib/features/pro/pro_screen.dart",
    "lib/services/tax_smart_service.dart",
]

def find_currency_formatters(file_path):
    """Find all NumberFormat instances in a file."""
    path = Path(file_path)
    if not path.exists():
        print(f"❌ File not found: {file_path}")
        return []
    
    content = path.read_text(encoding='utf-8')
    lines = content.split('\n')
    
    matches = []
    patterns = [
        (r'NumberFormat\.currency\([^)]+\)', 'NumberFormat.currency'),
        (r'NumberFormat\.compact\([^)]+\)', 'NumberFormat.compact'),
        (r'NumberFormat\.compactCurrency\([^)]+\)', 'NumberFormat.compactCurrency'),
    ]
    
    for line_num, line in enumerate(lines, 1):
        for pattern, name in patterns:
            if re.search(pattern, line):
                matches.append({
                    'line': line_num,
                    'type': name,
                    'content': line.strip()
                })
    
    return matches

def main():
    print("🔍 Scanning for NumberFormat instances...\n")
    
    total_count = 0
    for file_path in FILES_TO_CHECK:
        matches = find_currency_formatters(file_path)
        if matches:
            print(f"\n📄 {file_path} ({len(matches)} instances)")
            print("=" * 80)
            for match in matches:
                print(f"  Line {match['line']:4d}: {match['type']}")
                print(f"         {match['content'][:100]}")
            total_count += len(matches)
    
    print(f"\n{'='*80}")
    print(f"✅ Total instances found: {total_count}")
    print(f"\n💡 Replacement strategy:")
    print(f"   1. Add `final currency = _getCurrency(ref);` at method start")
    print(f"   2. Replace NumberFormat.currency() with CurrencyFormatter.format(amount, currency)")
    print(f"   3. Replace NumberFormat.compact() with CurrencyFormatter.formatCompact(amount, currency)")
    print(f"   4. For inline: Replace entire NumberFormat expression with CurrencyFormatter call")

if __name__ == "__main__":
    main()
