import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/order.dart';
import '../models/warranty.dart';

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class WarrantyService {
  // --- Customer ---
  Future<WarrantyClaim> fileClaim({
    required int orderId,
    required int declaredItemId,
    required String description,
    List<String> photoUrls = const [],
  }) async {
    try {
      final response = await ApiClient.dio.post('/orders/$orderId/claims', data: {
        'declaredItemId': declaredItemId,
        'description': description,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      });
      return WarrantyClaim.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to file claim.'));
    }
  }

  Future<List<WarrantyClaim>> orderClaims(int orderId) async {
    try {
      final response = await ApiClient.dio.get('/orders/$orderId/claims');
      return (response.data as List)
          .map((j) => WarrantyClaim.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load claims.'));
    }
  }

  // --- Partner ---
  Future<Order> confirmIntake(
    int orderId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/partner/orders/$orderId/intake',
        data: {'items': items},
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to confirm intake.'));
    }
  }

  Future<List<WarrantyClaim>> partnerClaims() async {
    try {
      final response = await ApiClient.dio.get('/partner/claims');
      return (response.data as List)
          .map((j) => WarrantyClaim.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load claims.'));
    }
  }

  Future<WarrantyClaim> resolveClaim(
    int claimId, {
    required String status, // APPROVED / REJECTED / RESOLVED
    String? note,
    double? payoutAmount,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/partner/claims/$claimId/resolve',
        data: {
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
          if (payoutAmount != null) 'payoutAmount': payoutAmount,
        },
      );
      return WarrantyClaim.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to resolve claim.'));
    }
  }
}
