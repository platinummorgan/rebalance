import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import web storage only on web platform
import 'web_storage.dart' if (dart.library.io) 'web_storage_stub.dart';

class ComparisonStorage {
  static const String _key = 'saved_comparisons';

  static Future<List<String>> getSavedComparisons() async {
    if (kIsWeb) {
      return await WebStorage.getSavedComparisons();
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    }
  }

  static Future<bool> saveSavedComparisons(List<String> comparisons) async {
    if (kIsWeb) {
      return await WebStorage.saveSavedComparisons(comparisons);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList(_key, comparisons);
    }
  }

  static Future<bool> addSavedComparison(String comparisonJson) async {
    try {
      final existing = await getSavedComparisons();
      existing.add(comparisonJson);
      return await saveSavedComparisons(existing);
    } catch (e) {
      debugPrint('Error adding comparison: $e');
      return false;
    }
  }

  static Future<bool> deleteSavedComparison(String id) async {
    try {
      final existing = await getSavedComparisons();
      final updated = existing.where((jsonString) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonString);
          return data['id'] != id;
        } catch (e) {
          return true; // Keep invalid entries for now
        }
      }).toList();
      return await saveSavedComparisons(updated);
    } catch (e) {
      debugPrint('Error deleting comparison: $e');
      return false;
    }
  }
}
