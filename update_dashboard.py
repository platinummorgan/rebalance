from pathlib import Path

path = Path('lib/features/dashboard/dashboard_screen.dart')
text = path.read_text()
if '\r\n' in text:
    text = text.replace('\r\n', '\n')

if "import 'package:flutter/foundation.dart';\n" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/foundation.dart';\n",
        1,
    )

success_pattern = """      Navigator.pop(context);\n      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Downloaded $filename • $timestamp ($timezone)'),\n            backgroundColor: Colors.green,\n          ),\n        );\n      }"""
success_replacement = """      if (!context.mounted) {\n        return;\n      }\n\n      Navigator.of(context).pop();\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Downloaded $filename • $timestamp ($timezone)'),\n          backgroundColor: Colors.green,\n        ),\n      );"""
if success_pattern not in text:
    raise SystemExit('success snackbar pattern not found')
text = text.replace(success_pattern, success_replacement, 1)

error_pattern = """    } catch (e) {\n      Navigator.pop(context);\n      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Download failed: ${e.toString()}'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n    }"""
error_replacement = """    } catch (e) {\n      debugPrint('Download failed: $e');\n      if (!context.mounted) {\n        return;\n      }\n\n      Navigator.of(context).pop();\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Download failed: ${e.toString()}'),\n          backgroundColor: Colors.red,\n        ),\n      );\n    }"""
if error_pattern not in text:
    raise SystemExit('error snackbar pattern not found')
text = text.replace(error_pattern, error_replacement, 1)

text = text.replace("print('Error saving comparison: $e');", "debugPrint('Error saving comparison: $e');")
text = text.replace("print('Error loading saved comparisons: ');", "debugPrint('Error loading saved comparisons: $e');")
text = text.replace("print('Error deleting saved comparison: ');", "debugPrint('Error deleting saved comparison: $e');")

old_store_snippet = """      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Failed to save comparison: ${e.toString()}'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n      return false;\n"""
new_store_snippet = """      if (!mounted) {\n        return false;\n      }\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Failed to save comparison: ${e.toString()}'),\n          backgroundColor: Colors.red,\n        ),\n      );\n      return false;\n"""
if old_store_snippet not in text:
    raise SystemExit('store snippet not found')
text = text.replace(old_store_snippet, new_store_snippet, 1)

old_save_block = """                if (context.mounted) {\n                  Navigator.of(context).pop();\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(\n                      content: Text('Saved comparison \"$name\"'),\n                      backgroundColor: Colors.green,\n                    ),\n                  );\n                }\n"""
new_save_block = """                if (!context.mounted) {\n                  return;\n                }\n\n                Navigator.of(context).pop();\n                ScaffoldMessenger.of(context).showSnackBar(\n                  SnackBar(\n                    content: Text('Saved comparison \"$name\"'),\n                    backgroundColor: Colors.green,\n                  ),\n                );\n"""
if old_save_block not in text:
    raise SystemExit('save block not found')
text = text.replace(old_save_block, new_save_block, 2)

snapshot_success = """      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(\n                'Snapshot saved • ${DateFormat('MMM d, h:mm a').format(DateTime.now())}'),\n            backgroundColor: Colors.green,\n            duration: const Duration(seconds: 2),\n          ),\n        );\n      }\n"""
snapshot_success_repl = """      if (!context.mounted) {\n        return;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text(\n              'Snapshot saved • ${DateFormat('MMM d, h:mm a').format(DateTime.now())}'),\n          backgroundColor: Colors.green,\n          duration: const Duration(seconds: 2),\n        ),\n      );\n"""
if snapshot_success not in text:
    raise SystemExit('snapshot success not found')
text = text.replace(snapshot_success, snapshot_success_repl, 1)

snapshot_error = """      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Failed to create snapshot: $e'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n"""
snapshot_error_repl = """      if (!context.mounted) {\n        return;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Failed to create snapshot: $e'),\n          backgroundColor: Colors.red,\n        ),\n      );\n"""
if snapshot_error not in text:
    raise SystemExit('snapshot error not found')
text = text.replace(snapshot_error, snapshot_error_repl, 1)

delete_success = """      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(\n                'Snapshot deleted • ${DateFormat('MMM d, h:mm a').format(snapshot.at)}'),\n            backgroundColor: Colors.orange,\n          ),\n        );\n      }\n"""
delete_success_repl = """      if (!context.mounted) {\n        return;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text(\n              'Snapshot deleted • ${DateFormat('MMM d, h:mm a').format(snapshot.at)}'),\n          backgroundColor: Colors.orange,\n        ),\n      );\n"""
if delete_success not in text:
    raise SystemExit('delete success not found')
text = text.replace(delete_success, delete_success_repl, 1)

delete_error = """      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Failed to delete snapshot: $e'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n"""
delete_error_repl = """      if (!context.mounted) {\n        return;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Failed to delete snapshot: $e'),\n          backgroundColor: Colors.red,\n        ),\n      );\n"""
if delete_error not in text:
    raise SystemExit('delete error not found')
text = text.replace(delete_error, delete_error_repl, 1)

old_delete_saved = """      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          const SnackBar(\n            content: Text('Deleted saved comparison'),\n            backgroundColor: Colors.green,\n          ),\n        );\n      }\n    } catch (e) {\n      debugPrint('Error deleting saved comparison: $e');\n      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          const SnackBar(\n            content: Text('Failed to delete comparison: ${e.toString()}'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n    }\n"""
new_delete_saved = """      if (!mounted) {\n        return;\n      }\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(\n          content: Text('Deleted saved comparison'),\n          backgroundColor: Colors.green,\n        ),\n      );\n    } catch (e) {\n      debugPrint('Error deleting saved comparison: $e');\n      if (!mounted) {\n        return;\n      }\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Failed to delete comparison: ${e.toString()}'),\n          backgroundColor: Colors.red,\n        ),\n      );\n    }\n"""
if old_delete_saved not in text:
    raise SystemExit('delete saved comparison block not found')
text = text.replace(old_delete_saved, new_delete_saved, 1)

old_popup_delete = """                                  await _deleteSavedComparison(comparison.id);\n                                  if (context.mounted) {\n                                    Navigator.of(context).pop();\n                                    _showSavedComparisonsDialog(context);\n                                  }\n"""
new_popup_delete = """                                  await _deleteSavedComparison(comparison.id);\n                                  if (!context.mounted) {\n                                    return;\n                                  }\n                                  Navigator.of(context).pop();\n                                  _showSavedComparisonsDialog(context);\n"""
if old_popup_delete not in text:
    raise SystemExit('popup delete block not found')
text = text.replace(old_popup_delete, new_popup_delete, 1)

path.write_text(text)
