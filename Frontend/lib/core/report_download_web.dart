// Web implementation: trigger a browser download of the CSV text.
import 'dart:js_interop';

@JS('document.createElement')
external _Anchor _createAnchor(String tag);

extension type _Anchor._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

/// Download [content] as a file named [filename] via a data URL. Returns a
/// human-readable location note.
Future<String> downloadTextFile(String filename, String content) async {
  final dataUrl =
      'data:text/csv;charset=utf-8,${Uri.encodeComponent(content)}';
  final anchor = _createAnchor('a')
    ..href = dataUrl
    ..download = filename;
  anchor.click();
  return 'your Downloads folder';
}
