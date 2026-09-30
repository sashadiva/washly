import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/wallet.dart';

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class LoyaltyService {
  Future<Wallet> wallet() async {
    try {
      final response = await ApiClient.dio.get('/loyalty/wallet');
      return Wallet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load wallet.'));
    }
  }

  /// Redeem a chosen reward tier for a voucher. Returns the new balance.
  Future<int> redeem(String tierId) async {
    try {
      final response = await ApiClient.dio.post(
        '/loyalty/redeem',
        data: {'tierId': tierId},
      );
      return (response.data as Map<String, dynamic>)['balance'] as int;
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to redeem voucher.'));
    }
  }
}
