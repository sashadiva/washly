import 'package:dio/dio.dart';
import '../core/api_client.dart';

/// Result of creating a Snap transaction on the backend.
class SnapPayment {
  final String snapToken;
  final String redirectUrl;
  final String midtransOrderId;
  final double amount;

  SnapPayment({
    required this.snapToken,
    required this.redirectUrl,
    required this.midtransOrderId,
    required this.amount,
  });

  factory SnapPayment.fromJson(Map<String, dynamic> json) {
    return SnapPayment(
      snapToken: json['snapToken'] as String,
      redirectUrl: json['redirectUrl'] as String? ?? '',
      midtransOrderId: json['midtransOrderId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class PaymentService {
  /// Ask the backend to create a Midtrans Snap transaction for an order.
  Future<SnapPayment> createPayment(int orderId) async {
    try {
      final response = await ApiClient.dio.post('/payments/$orderId/create');
      return SnapPayment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to start payment.'));
    }
  }
}
