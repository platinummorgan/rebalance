from pathlib import Path
import re

path = Path('lib/features/dashboard/dashboard_screen.dart')
text = path.read_text().replace('\r\n','\n')

pattern = re.compile(r"if \(context\.mounted\) \{\n( +)ScaffoldMessenger", re.MULTILINE)

def repl(match):
    indent = match.group(1)
    return f"if (!context.mounted) {{\n{indent}return;\n}}\n\n{indent}ScaffoldMessenger"

text, count = pattern.subn(repl, text)

# For occurrences where nested block uses const SnackBar? Already covered as same pattern.

path.write_text(text)
print(f"Replaced {count} occurrences")
