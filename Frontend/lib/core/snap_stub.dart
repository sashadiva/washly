// Non-web stub for the Snap popup. Mobile/desktop use the URL launcher
// instead, so this should never be called there; it throws if it is.
enum SnapOutcome { success, pending, error, closed }

Future<SnapOutcome> openSnapPopup(String token) {
  throw UnsupportedError('Snap popup is only available on web.');
}
