import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class CsvExportHelper {
  static void exportCsvData(String csvData, String fileName) {
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();

    html.Url.revokeObjectUrl(url);
  }
}
