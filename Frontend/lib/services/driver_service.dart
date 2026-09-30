import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/driver.dart';
import '../models/order.dart';

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class DriverService {
  Future<List<DeliveryOffer>> offers() async {
    try {
      final response = await ApiClient.dio.get('/driver/offers');
      return (response.data as List)
          .map((j) => DeliveryOffer.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load offers.'));
    }
  }

  Future<Order> acceptOffer(int offerId) async {
    try {
      final response =
          await ApiClient.dio.post('/driver/offers/$offerId/accept');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to accept offer.'));
    }
  }

  Future<void> rejectOffer(int offerId) async {
    try {
      await ApiClient.dio.post('/driver/offers/$offerId/reject');
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to reject offer.'));
    }
  }

  /// The driver's current in-progress assignment, or null.
  Future<Order?> active() async {
    try {
      final response = await ApiClient.dio.get('/driver/active');
      if (response.data == null) return null;
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load active delivery.'));
    }
  }

  Future<Order> markPickedUp(int orderId) async {
    try {
      final response =
          await ApiClient.dio.post('/driver/orders/$orderId/picked-up');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to update order.'));
    }
  }

  Future<Order> markDelivered(int orderId) async {
    try {
      final response =
          await ApiClient.dio.post('/driver/orders/$orderId/delivered');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to update order.'));
    }
  }

  Future<List<Order>> history() async {
    try {
      final response = await ApiClient.dio.get('/driver/history');
      return (response.data as List)
          .map((j) => Order.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load history.'));
    }
  }

  Future<DriverProfile> profile() async {
    try {
      final response = await ApiClient.dio.get('/driver/profile');
      return DriverProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load profile.'));
    }
  }

  /// Toggle availability. `active` true -> AVAILABLE, false -> OFFLINE.
  Future<DriverProfile> setAvailability(bool active,
      {double? latitude, double? longitude}) async {
    try {
      final response = await ApiClient.dio.put('/driver/availability', data: {
        'active': active,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      return DriverProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to update availability.'));
    }
  }
}
