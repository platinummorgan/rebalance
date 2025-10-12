import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Utility for saving CSV exports to Downloads folder.
class CsvExporter {
  const CsvExporter._();

  /// Saves [csvContent] as a `.csv` file using [fileName] (without extension).
  ///
  /// Returns the full file path where the file was saved.
  static Future<String> save({
    required String fileName,
    required String csvContent,
  }) async {
    // Get Downloads directory
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      // Android: Prefer the public Downloads folder via path_provider
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          downloadsDir = dirs.first;
        } else {
          // Fallback for older devices or if API not available
          downloadsDir = Directory('/storage/emulated/0/Download');
        }
      } catch (e) {
        // If anything goes wrong, fallback to the common Downloads path
        downloadsDir = Directory('/storage/emulated/0/Download');
      }
      debugPrint('CsvExporter: using downloadsDir=${downloadsDir.path}');
    } else if (Platform.isIOS) {
      // iOS: Use app documents directory (iOS doesn't have a public Downloads)
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      // Desktop/other platforms
      downloadsDir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }

    // Create file with .csv extension
    final file = File('${downloadsDir.path}/$fileName.csv');

    // Write CSV content
    await file.writeAsString(csvContent);

    // Return the full path
    return file.path;
  }
}
