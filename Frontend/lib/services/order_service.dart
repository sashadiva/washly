import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// A declared item (label + photo) captured at checkout for the warranty
/// window. `photoUrl` is a data URI or hosted URL in this prototype.
class DeclaredItemInput {
  final String label;
  final String photoUrl;
  DeclaredItemInput({required this.label, required this.photoUrl});

  Map<String, dynamic> toJson() => {'label': label, 'photoUrl': photoUrl};
}

/// Turns Dio errors into readable messages using the backend `{ error }` shape.
String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class OrderService {
  /// Create an order from the current cart. The customer id comes from the JWT
  /// on the server, never the body. Returns the created rich [Order].
  Future<Order> createOrder({
    required int laundromatId,
    required String pickupAddress,
    String? deliveryAddress,
    String? notes,
    double? customerLat,
    double? customerLng,
    required List<CartItem> cart,
    List<DeclaredItemInput>? declaredItems,
    int? voucherId,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/orders',
        data: {
          'laundromatId': laundromatId,
          'pickupAddress': pickupAddress,
          if (deliveryAddress != null && deliveryAddress.isNotEmpty)
            'deliveryAddress': deliveryAddress,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (customerLat != null) 'customerLat': customerLat,
          if (customerLng != null) 'customerLng': customerLng,
          'items': cart
              .map((c) => {
                    'serviceId': c.serviceId,
                    'quantity': c.quantity,
                    if (c.notes != null && c.notes!.isNotEmpty) 'notes': c.notes,
                  })
              .toList(),
          if (declaredItems != null && declaredItems.isNotEmpty)
            'declaredItems': declaredItems.map((d) => d.toJson()).toList(),
          if (voucherId != null) 'voucherId': voucherId,
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to create order.'));
    }
  }

  /// The authenticated customer's orders, newest first.
  Future<List<Order>> myOrders() async {
    try {
      final response = await ApiClient.dio.get('/orders/mine');
      final data = response.data as List;
      return data
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load orders.'));
    }
  }

  /// A single owned order with full detail (items, declared items, payments).
  Future<Order> getOrder(int id) async {
    try {
      final response = await ApiClient.dio.get('/orders/$id');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to load order.'));
    }
  }

  /// Approve the weighed price on a per-kg order
  /// (WEIGHED_AWAITING_CONFIRM -> AWAITING_PAYMENT).
  Future<Order> approveWeight(int id) async {
    try {
      final response = await ApiClient.dio.post('/orders/$id/approve-weight');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Failed to approve weight.'));
    }
  }
}
