// Stub file for non-web platforms
class WebStorage {
  static Future<List<String>> getSavedComparisons() async {
    throw UnsupportedError('WebStorage is only available on web platforms');
  }

  static Future<bool> saveSavedComparisons(List<String> comparisons) async {
    throw UnsupportedError('WebStorage is only available on web platforms');
  }

  static Future<bool> addSavedComparison(String comparisonJson) async {
    throw UnsupportedError('WebStorage is only available on web platforms');
  }
}
