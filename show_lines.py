from pathlib import Path
path = Path(r'lib/features/dashboard/dashboard_screen.dart')
lines = path.read_text().splitlines()
for i in range(3670, 3710):
    print(f"{i}: {lines[i-1]}")
