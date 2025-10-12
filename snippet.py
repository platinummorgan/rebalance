from pathlib import Path
text = Path('lib/features/dashboard/dashboard_screen.dart').read_text().replace('\r\n','\n')
block = "                if (context.mounted) {\n                  Navigator.of(context).pop();\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(\n                      content: Text('Saved comparison \"$name\"'),\n                      backgroundColor: Colors.green,\n                    ),\n                  );\n                }\n"
print(block in text)
