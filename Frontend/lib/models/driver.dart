// Driver-facing models: delivery offers and the driver profile/availability.
import 'order.dart';

/// A pending delivery offer (pickup or delivery leg) for a driver.
class DeliveryOffer {
  final int id;
  final String phase; // 'PICKUP' or 'DELIVERY'
  final String status; // OFFERED/ACCEPTED/REJECTED/EXPIRED
  final int orderId;
  final Order order;

  DeliveryOffer({
    required this.id,
    required this.phase,
    required this.status,
    required this.orderId,
    required this.order,
  });

  bool get isPickup => phase == 'PICKUP';

  factory DeliveryOffer.fromJson(Map<String, dynamic> json) {
    return DeliveryOffer(
      id: json['id'] as int,
      phase: json['phase'] as String? ?? 'PICKUP',
      status: json['status'] as String? ?? 'OFFERED',
      orderId: json['orderId'] as int,
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
    );
  }
}

/// The driver's own profile + availability.
class DriverProfile {
  final int id;
  final String vehicleType;
  final String plateNumber;
  final String availability; // AVAILABLE / BUSY / OFFLINE
  final double? latitude;
  final double? longitude;

  DriverProfile({
    required this.id,
    required this.vehicleType,
    required this.plateNumber,
    required this.availability,
    this.latitude,
    this.longitude,
  });

  bool get isActive => availability == 'AVAILABLE';
  bool get isBusy => availability == 'BUSY';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as int,
      vehicleType: json['vehicleType'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      availability: json['availability'] as String? ?? 'OFFLINE',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
