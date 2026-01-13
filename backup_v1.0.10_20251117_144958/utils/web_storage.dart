// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class WebStorage {
  static const String _savedComparisonsKey = 'wealth_dial_saved_comparisons';

  static Future<List<String>> getSavedComparisons() async {
    try {
      final stored = html.window.localStorage[_savedComparisonsKey];
      if (stored == null || stored.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(stored);
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('Error loading saved comparisons: $e');
      return [];
    }
  }

  static Future<bool> saveSavedComparisons(List<String> comparisons) async {
    try {
      final encoded = jsonEncode(comparisons);
      html.window.localStorage[_savedComparisonsKey] = encoded;
      return true;
    } catch (e) {
      debugPrint('Error saving comparisons: $e');
      return false;
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
}
