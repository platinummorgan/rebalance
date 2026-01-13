import 'package:flutter/services.dart';

/// Service for saving files to device storage using native Android methods
class FileSaverService {
  static const platform = MethodChannel('com.wealthdial.app/file_saver');

  /// Save a file to the Downloads folder using native Android MediaStore API
  ///
  /// This works on all Android versions:
  /// - Android 10+ (API 29+): Uses MediaStore API (no permissions needed)
  /// - Android 9 and below: Uses direct file access (requires WRITE_EXTERNAL_STORAGE)
  ///
  /// Returns the file path where the file was saved
  static Future<String> saveToDownloads({
    required String fileName,
    required String content,
  }) async {
    try {
      final String result = await platform.invokeMethod('saveToDownloads', {
        'fileName': fileName,
        'content': content,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to save file: ${e.message}');
    }
  }
}
