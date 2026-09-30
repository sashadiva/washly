// Web-only Midtrans Snap popup binding via dart:js_interop.
//
// Snap.js is loaded in web/index.html with the sandbox client key, exposing
// `window.snap.pay(token, callbacks)`. This opens an embedded payment popup
// (no tab navigation) and invokes callbacks with the result.
import 'dart:async';
import 'dart:js_interop';

/// The outcome the popup reports back.
enum SnapOutcome { success, pending, error, closed }

@JS('snap.pay')
external void _snapPay(String token, _SnapCallbacks callbacks);

extension type _SnapCallbacks._(JSObject _) implements JSObject {
  external factory _SnapCallbacks({
    JSFunction onSuccess,
    JSFunction onPending,
    JSFunction onError,
    JSFunction onClose,
  });
}

/// Opens the Snap popup for [token] and completes with the reported outcome.
/// Completes with [SnapOutcome.closed] if the user dismisses the popup.
Future<SnapOutcome> openSnapPopup(String token) {
  final completer = Completer<SnapOutcome>();
  void done(SnapOutcome o) {
    if (!completer.isCompleted) completer.complete(o);
  }

  _snapPay(
    token,
    _SnapCallbacks(
      onSuccess: ((JSAny _) => done(SnapOutcome.success)).toJS,
      onPending: ((JSAny _) => done(SnapOutcome.pending)).toJS,
      onError: ((JSAny _) => done(SnapOutcome.error)).toJS,
      onClose: (() => done(SnapOutcome.closed)).toJS,
    ),
  );

  return completer.future;
}
