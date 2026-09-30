// Conditional export: real Snap popup on web, throwing stub elsewhere.
export 'snap_stub.dart' if (dart.library.js_interop) 'snap_web.dart';
