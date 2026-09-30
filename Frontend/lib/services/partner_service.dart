import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/order.dart';
import '../models/partner_profile.dart';

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class PartnerService {
  // --- Orders ---
  Future<List<Order>> orders() async {
    try {
      final response = await ApiClient.dio.get('/partner/orders');
      return (response.data as List)
          .map((j) => Order.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load orders.'));
    }
  }

  Future<Order> accept(int orderId) => _orderAction(orderId, 'accept');
  Future<Order> reject(int orderId) => _orderAction(orderId, 'reject');
  Future<Order> markReady(int orderId) => _orderAction(orderId, 'ready');

  Future<Order> weigh(int orderId, double weighedKg) async {
    try {
      final response = await ApiClient.dio.post(
        '/partner/orders/$orderId/weigh',
        data: {'weighedKg': weighedKg},
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to record weight.'));
    }
  }

  Future<Order> _orderAction(int orderId, String action) async {
    try {
      final response =
          await ApiClient.dio.post('/partner/orders/$orderId/$action');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Action failed.'));
    }
  }

  // --- Profile ---
  Future<PartnerProfile> profile() async {
    try {
      final response = await ApiClient.dio.get('/partner/profile');
      return PartnerProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load profile.'));
    }
  }

  Future<PartnerProfile> updateProfile({
    String? name,
    String? description,
    String? address,
    String? areaLabel,
    double? latitude,
    double? longitude,
    String? imageUrl,
    bool? isOpen,
    List<String>? specialties,
  }) async {
    try {
      final response = await ApiClient.dio.put('/partner/profile', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (address != null) 'address': address,
        if (areaLabel != null) 'areaLabel': areaLabel,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (isOpen != null) 'isOpen': isOpen,
        if (specialties != null) 'specialties': specialties,
      });
      return PartnerProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to update profile.'));
    }
  }

  // --- Services ---
  Future<List<ShopService>> services() async {
    try {
      final response = await ApiClient.dio.get('/partner/services');
      return (response.data as List)
          .map((j) => ShopService.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load services.'));
    }
  }

  Future<ShopService> createService({
    required String name,
    String? description,
    required double price,
    required String unit,
  }) async {
    try {
      final response = await ApiClient.dio.post('/partner/services', data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'price': price,
        'unit': unit,
      });
      return ShopService.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to create service.'));
    }
  }

  Future<ShopService> updateService(
    int id, {
    String? name,
    String? description,
    double? price,
    String? unit,
  }) async {
    try {
      final response =
          await ApiClient.dio.put('/partner/services/$id', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (unit != null) 'unit': unit,
      });
      return ShopService.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to update service.'));
    }
  }

  Future<void> deleteService(int id) async {
    try {
      await ApiClient.dio.delete('/partner/services/$id');
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to delete service.'));
    }
  }

  // --- Dashboard ---
  Future<PartnerDashboard> dashboard() async {
    try {
      final response = await ApiClient.dio.get('/partner/dashboard');
      return PartnerDashboard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load dashboard.'));
    }
  }
}
