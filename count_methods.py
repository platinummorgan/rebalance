from pathlib import Path
text = Path('lib/features/dashboard/dashboard_screen.dart').read_text(encoding='utf-8')
print(text.count('Future<bool> _storeSavedComparison'))
print(text.count('Future<void> _deleteSavedComparison'))
