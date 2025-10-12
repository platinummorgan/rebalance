from pathlib import Path
text = Path('lib/features/dashboard/dashboard_screen.dart').read_text(encoding='utf-8')
for i, line in enumerate(text.splitlines(), 1):
    if line.startswith('Container '):
        print(i, line)
