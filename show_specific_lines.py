from pathlib import Path
path = Path('lib/features/dashboard/dashboard_screen.dart')
lines = path.read_text().splitlines()
for i in [2469,2481,3390,3400,3659,3792,3797,3935,3945,4537,4546,5014,5046]:
    print(f"{i}: {lines[i-1]}")
