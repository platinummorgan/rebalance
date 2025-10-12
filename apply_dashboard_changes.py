from pathlib import Path

path = Path('lib/features/dashboard/dashboard_screen.dart')
text = path.read_text(encoding='utf-8').replace('\r\n','\n')

text = text.replace("import 'package:shared_preferences/shared_preferences.dart';\n", '')

if "import 'package:flutter/foundation.dart';\n" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/foundation.dart';\n",
        1,
    )

text = text.replace(
    "// In a real app, you'd store this in SharedPreferences or similar",
    "// In a real app, you'd store this via ComparisonStorage or similar persistent storage",
)

old_store = """  Future<void> _storeSavedComparison(SavedComparison comparison) async {\n    try {\n      final prefs = await SharedPreferences.getInstance();\n\n      // Get existing saved comparisons\n      final savedComparisonsJson =\n          prefs.getStringList('saved_comparisons') ?? [];\n\n      // Add the new comparison\n      savedComparisonsJson.add(jsonEncode(comparison.toMap()));\n\n      // Save back to preferences\n      await prefs.setStringList('saved_comparisons', savedComparisonsJson);\n    } catch (e) {\n      // Handle storage error\n      print('Error saving comparison: $e');\n      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Failed to save comparison: ${e.toString()}'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n    }\n  }\n\n"""
new_store = """  Future<bool> _storeSavedComparison(SavedComparison comparison) async {\n    try {\n      final comparisonJson = jsonEncode(comparison.toMap());\n      final success =\n          await ComparisonStorage.addSavedComparison(comparisonJson);\n\n      if (!success) {\n        throw Exception('Failed to persist saved comparison');\n      }\n\n      return true;\n    } catch (e) {\n      debugPrint('Error saving comparison: $e');\n      if (!mounted) {\n        return false;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Failed to save comparison: ${e.toString()}'),\n          backgroundColor: Colors.red,\n        ),\n      );\n      return false;\n    }\n  }\n\n"""
if old_store not in text:
    raise SystemExit('store block not found')
text = text.replace(old_store, new_store, 1)

old_load = """  Future<List<SavedComparison>> _loadSavedComparisons() async {\n    try {\n      final prefs = await SharedPreferences.getInstance();\n      final savedComparisonsJson =\n          prefs.getStringList('saved_comparisons') ?? [];\n\n      return savedComparisonsJson\n          .map((json) => SavedComparison.fromMap(jsonDecode(json)))\n          .toList()\n        ..sort((a, b) => b.createdAt\n            .compareTo(a.createdAt)); // Sort by creation date, newest first\n    } catch (e) {\n      print('Error loading saved comparisons: $e');\n      return [];\n    }\n  }\n\n"""
new_load = """  Future<List<SavedComparison>> _loadSavedComparisons() async {\n    try {\n      final savedComparisonsJson =\n          await ComparisonStorage.getSavedComparisons();\n\n      return savedComparisonsJson\n          .map((json) => SavedComparison.fromMap(jsonDecode(json)))\n          .toList()\n        ..sort((a, b) => b.createdAt\n            .compareTo(a.createdAt)); // Sort by creation date, newest first\n    } catch (e) {\n      debugPrint('Error loading saved comparisons: $e');\n      return [];\n    }\n  }\n\n"""
if old_load not in text:
    raise SystemExit('load block not found')
text = text.replace(old_load, new_load, 1)

old_delete = """  Future<void> _deleteSavedComparison(String comparisonId) async {\n    try {\n      final prefs = await SharedPreferences.getInstance();\n      final savedComparisonsJson =\n          prefs.getStringList('saved_comparisons') ?? [];\n\n      // Remove the comparison with the matching ID\n      savedComparisonsJson.removeWhere((json) {\n        final comparison = SavedComparison.fromMap(jsonDecode(json));\n        return comparison.id == comparisonId;\n      });\n\n      // Save back to preferences\n      await prefs.setStringList('saved_comparisons', savedComparisonsJson);\n\n      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          const SnackBar(\n            content: Text('Deleted saved comparison'),\n            backgroundColor: Colors.green,\n          ),\n        );\n      }\n    } catch (e) {\n      print('Error deleting saved comparison: $e');\n      if (context.mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('Failed to delete comparison: ${e.toString()}'),\n            backgroundColor: Colors.red,\n          ),\n        );\n      }\n    }\n  }\n\n"""
new_delete = """  Future<void> _deleteSavedComparison(String comparisonId) async {\n    try {\n      final savedComparisonsJson =\n          await ComparisonStorage.getSavedComparisons();\n\n      final updatedComparisons = savedComparisonsJson.where((json) {\n        final comparison = SavedComparison.fromMap(jsonDecode(json));\n        return comparison.id != comparisonId;\n      }).toList();\n\n      final success =\n          await ComparisonStorage.saveSavedComparisons(updatedComparisons);\n\n      if (!success) {\n        throw Exception('Failed to persist saved comparisons');\n      }\n\n      if (!mounted) {\n        return;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(\n          content: Text('Deleted saved comparison'),\n          backgroundColor: Colors.green,\n        ),\n      );\n    } catch (e) {\n      debugPrint('Error deleting saved comparison: $e');\n      if (!mounted) {\n        return;\n      }\n\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('Failed to delete comparison: ${e.toString()}'),\n          backgroundColor: Colors.red,\n        ),\n      );\n    }\n  }\n\n"""
if old_delete not in text:
    raise SystemExit('delete block not found')
text = text.replace(old_delete, new_delete, 1)

call_pattern = """                await _storeSavedComparison(savedComparison);\n\n                if (context.mounted) {\n                  Navigator.of(context).pop();\n                  ScaffoldMessenger.of(context).showSnackBar(\n                    SnackBar(\n                      content: Text('Saved comparison \"$name\"'),\n                      backgroundColor: Colors.green,\n                    ),\n                  );\n                }\n"""
call_replacement = """                final saved = await _storeSavedComparison(savedComparison);\n\n                if (!saved) {\n                  return;\n                }\n\n                if (!context.mounted) {\n                  return;\n                }\n\n                Navigator.of(context).pop();\n                ScaffoldMessenger.of(context).showSnackBar(\n                  SnackBar(\n                    content: Text('Saved comparison \"$name\"'),\n                    backgroundColor: Colors.green,\n                  ),\n                );\n"""
if call_pattern not in text:
    raise SystemExit('store call pattern not found')
text = text.replace(call_pattern, call_replacement, 1)

popup_pattern = """                                  await _deleteSavedComparison(comparison.id);\n                                  if (context.mounted) {\n                                    Navigator.of(context).pop();\n                                    _showSavedComparisonsDialog(context);\n                                  }\n"""
popup_replacement = """                                  await _deleteSavedComparison(comparison.id);\n                                  if (!context.mounted) {\n                                    return;\n                                  }\n                                  Navigator.of(context).pop();\n                                  _showSavedComparisonsDialog(context);\n"""
if popup_pattern not in text:
    raise SystemExit('popup pattern not found')
text = text.replace(popup_pattern, popup_replacement, 1)

Path('lib/features/dashboard/dashboard_screen.dart').write_text(text, encoding='utf-8')
