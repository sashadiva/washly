// IO implementation: write the CSV to a temp file and return its path.
import 'dart:io';

/// Save [content] to a file named [filename] in the system temp dir. Returns
/// the saved file path.
Future<String> downloadTextFile(String filename, String content) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}
