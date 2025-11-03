import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Utility for saving CSV exports to Downloads folder.
class CsvExporter {
  const CsvExporter._();

  /// Shares [csvContent] as a `.csv` file using [fileName] (without extension).
  ///
  /// Uses the system share dialog to let the user choose where to save the file.
  /// This works better on modern Android versions (13+) with scoped storage.
  ///
  /// Returns the result of the share operation.
  static Future<ShareResult> save({
    required String fileName,
    required String csvContent,
  }) async {
    // Create a temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName.csv');

    // Write CSV content to temp file
    await file.writeAsString(csvContent);

    // Share the file using the system share dialog with CSV MIME type
    // This allows the user to save to Downloads, Google Drive, email, etc.
    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Rebalance Export',
      text: 'Financial data export from Rebalance',
    );

    return result;
  }

  /// Direct save to public Downloads folder
  /// For Android 10+ (API 29+), this uses the standard /storage/emulated/0/Download path
  static Future<String> saveDirect({
    required String fileName,
    required String csvContent,
  }) async {
    if (Platform.isAndroid) {
      // Use the public Downloads folder directly
      // This is accessible to the user via Files app
      final downloadsDir = Directory('/storage/emulated/0/Download');

      // Create directory if it doesn't exist (it should always exist)
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      debugPrint('CsvExporter: using downloadsDir=${downloadsDir.path}');

      // Create file with .csv extension
      final file = File('${downloadsDir.path}/$fileName.csv');

      // Write CSV content
      await file.writeAsString(csvContent);

      debugPrint('CsvExporter: file saved to ${file.path}');

      // Return the full path
      return file.path;
    } else if (Platform.isIOS) {
      // iOS: Use app documents directory (iOS doesn't have a public Downloads)
      final downloadsDir = await getApplicationDocumentsDirectory();
      final file = File('${downloadsDir.path}/$fileName.csv');
      await file.writeAsString(csvContent);
      return file.path;
    } else {
      // Desktop/other platforms
      final downloadsDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${downloadsDir.path}/$fileName.csv');
      await file.writeAsString(csvContent);
      return file.path;
    }
  }
}
