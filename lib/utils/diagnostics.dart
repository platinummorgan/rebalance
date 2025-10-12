import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/repositories.dart';

class Diagnostics {
  /// Collect diagnostics from RepositoryService and write to a temporary
  /// JSON file, then open the platform share sheet so the user can send it.
  static Future<File> collectAndWrite() async {
    final data = await RepositoryService.collectDiagnostics();

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'wealth_dial_diagnostics_$timestamp.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  static Future<void> shareDiagnosticsFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Wealth Dial diagnostics',
    );
  }
}
