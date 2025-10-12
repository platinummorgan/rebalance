from pathlib import Path
text = Path('lib/features/dashboard/dashboard_screen.dart').read_text(encoding='utf-8')
idx = text.find("In a real app, you'd store this in SharedPreferences")
print(idx)
if idx != -1:
    print(text[idx:idx+200])
