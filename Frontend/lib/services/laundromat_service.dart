import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/laundromat.dart';
import '../models/laundromat_detail.dart';

class LaundromatService {
  /// Fetch discovery list with optional tag filtering and distance/rating sorting
  Future<List<Laundromat>> fetchLaundromats({
    List<String>? selectedTags,
    String sortBy = 'rating', // 'rating' or 'distance'
    double? lat,
    double? lng,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'sort': sortBy,
      };

      if (selectedTags != null && selectedTags.isNotEmpty) {
        queryParams['tags'] = selectedTags.join(',');
      }

      if (lat != null && lng != null) {
        queryParams['userLat'] = lat.toString();
        queryParams['userLng'] = lng.toString();
      }

      final response = await ApiClient.dio.get(
        '/laundromats',
        queryParameters: queryParams,
      );

      final data = response.data as List;
      return data
          .map((json) => Laundromat.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load laundromats: ${e.response?.data?['error'] ?? e.message}',
      );
    }
  }

  /// Fetch single laundromat details including all customer reviews
  Future<LaundromatDetail> getLaundromatDetail(int id) async {
    try {
      final response = await ApiClient.dio.get('/laundromats/$id');
      return LaundromatDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        'Failed to load store details: ${e.response?.data?['error'] ?? e.message}',
      );
    }
  }

  /// Create a pickup and return laundry order
  Future<void> createOrder({
    required int laundromatId,
    required int customerId,
    required String pickupAddress,
    String? deliveryAddress,
    required String serviceType,
    String? notes,
    double? estimatedKg,
  }) async {
    try {
      await ApiClient.dio.post(
        '/orders',
        data: {
          'laundromatId': laundromatId,
          'customerId': customerId,
          'pickupAddress': pickupAddress,
          'deliveryAddress': deliveryAddress ?? pickupAddress,
          'serviceType': serviceType,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (estimatedKg != null) 'estimatedKg': estimatedKg,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to create order: ${e.response?.data?['error'] ?? e.message}',
      );
    }
  }

  /// Submit a review and rating (1-5) for a laundromat
  Future<void> addReview({
    required int laundromatId,
    required int userId,
    required int rating,
    required String comment,
  }) async {
    try {
      await ApiClient.dio.post(
        '/laundromats/$laundromatId/reviews',
        data: {
          'userId': userId,
          'rating': rating,
          'comment': comment,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to submit review: ${e.response?.data?['error'] ?? e.message}',
      );
    }
  }
}