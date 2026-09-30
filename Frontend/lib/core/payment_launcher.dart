import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'snap.dart';

/// The result of a payment attempt as reported to the UI.
enum PaymentResult { success, pending, error, closed, launched }

/// Isolates the platform difference for opening a Midtrans Snap payment.
///
/// On web we use Snap.js's embedded popup (`window.snap.pay`), which overlays
/// the payment UI without navigating away and reports the outcome via
/// callbacks — no polling needed. On mobile/desktop we open the hosted Snap
/// page in the external browser. The webhook remains the source of truth for
/// settlement; the popup callback is a UX convenience.
class PaymentLauncher {
  final PaymentService _payments;
  final OrderService _orders;

  PaymentLauncher({PaymentService? payments, OrderService? orders})
      : _payments = payments ?? PaymentService(),
        _orders = orders ?? OrderService();

  /// Create the Snap transaction and present payment.
  ///
  /// Web: opens the embedded popup and resolves with the real outcome
  /// (success/pending/error/closed). Mobile: opens the browser and resolves
  /// with [PaymentResult.launched] (the caller should refresh/poll later).
  Future<PaymentResult> launch(int orderId) async {
    final snap = await _payments.createPayment(orderId);

    if (kIsWeb) {
      final outcome = await openSnapPopup(snap.snapToken);
      switch (outcome) {
        case SnapOutcome.success:
          return PaymentResult.success;
        case SnapOutcome.pending:
          return PaymentResult.pending;
        case SnapOutcome.error:
          return PaymentResult.error;
        case SnapOutcome.closed:
          return PaymentResult.closed;
      }
    }

    final uri = Uri.parse(
      snap.redirectUrl.isNotEmpty
          ? snap.redirectUrl
          : 'https://app.sandbox.midtrans.com/snap/v2/vtweb/${snap.snapToken}',
    );
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open the payment page.');
    }
    return PaymentResult.launched;
  }

  /// Poll the order until it leaves the pre-payment state (settled via the
  /// webhook) or the timeout elapses. Returns the latest order seen.
  Future<Order> awaitSettlement(
    int orderId, {
    Set<OrderStatus> preStatuses = const {
      OrderStatus.pendingAcceptance,
      OrderStatus.awaitingPayment,
    },
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Order latest = await _orders.getOrder(orderId);
    while (preStatuses.contains(latest.status) &&
        DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);
      latest = await _orders.getOrder(orderId);
    }
    return latest;
  }
}
