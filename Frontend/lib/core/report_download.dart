// Conditional export: browser download on web, file save on IO platforms.
export 'report_download_io.dart'
    if (dart.library.js_interop) 'report_download_web.dart';
