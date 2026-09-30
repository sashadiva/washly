// Rich customer-facing order models, mirroring the backend `ORDER_INCLUDE`
// response shape (see Backend/src/routes/order.ts). Hand-written, no codegen,
// matching the existing model conventions.

/// The 11 lifecycle states from the backend `OrderStatus` enum.
enum OrderStatus {
  pendingAcceptance,
  accepted,
  driverAssigned,
  pickedUp,
  weighedAwaitingConfirm,
  awaitingPayment,
  washing,
  readyForDelivery,
  outForDelivery,
  completed,
  cancelled,
  unknown,
}

OrderStatus orderStatusFromString(String value) {
  switch (value.toUpperCase()) {
    case 'PENDING_ACCEPTANCE':
      return OrderStatus.pendingAcceptance;
    case 'ACCEPTED':
      return OrderStatus.accepted;
    case 'DRIVER_ASSIGNED':
      return OrderStatus.driverAssigned;
    case 'PICKED_UP':
      return OrderStatus.pickedUp;
    case 'WEIGHED_AWAITING_CONFIRM':
      return OrderStatus.weighedAwaitingConfirm;
    case 'AWAITING_PAYMENT':
      return OrderStatus.awaitingPayment;
    case 'WASHING':
      return OrderStatus.washing;
    case 'READY_FOR_DELIVERY':
      return OrderStatus.readyForDelivery;
    case 'OUT_FOR_DELIVERY':
      return OrderStatus.outForDelivery;
    case 'COMPLETED':
      return OrderStatus.completed;
    case 'CANCELLED':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.unknown;
  }
}

extension OrderStatusX on OrderStatus {
  /// Human-readable label for chips and timelines.
  String get label {
    switch (this) {
      case OrderStatus.pendingAcceptance:
        return 'Waiting for partner';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.driverAssigned:
        return 'Driver assigned';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.weighedAwaitingConfirm:
        return 'Awaiting your confirmation';
      case OrderStatus.awaitingPayment:
        return 'Awaiting payment';
      case OrderStatus.washing:
        return 'Washing';
      case OrderStatus.readyForDelivery:
        return 'Ready for delivery';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;

  /// True while the order is still in an active/in-progress state.
  bool get isActive => !isTerminal;
}

/// One line item on an order. `lineTotal` is null for per-kg items until the
/// partner weighs them.
class OrderItem {
  final int id;
  final int serviceId;
  final String serviceName;
  final String unit; // 'PER_KG' or 'PER_ITEM'
  final double unitPrice;
  final double quantity; // pieces (per-item) or estimated kg (per-kg)
  final double? lineTotal;
  final String? notes;

  OrderItem({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
    this.lineTotal,
    this.notes,
  });

  bool get isKilo => unit == 'PER_KG';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      serviceId: json['serviceId'] as int,
      serviceName: json['serviceName'] as String,
      unit: json['unit'] as String? ?? 'PER_ITEM',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      lineTotal: json['lineTotal'] == null
          ? null
          : (json['lineTotal'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// A declared item captured at checkout for the warranty window.
class DeclaredItem {
  final int id;
  final String label;
  final String photoUrl;
  final bool confirmedReceived;
  final String? discrepancyNote;

  DeclaredItem({
    required this.id,
    required this.label,
    required this.photoUrl,
    required this.confirmedReceived,
    this.discrepancyNote,
  });

  factory DeclaredItem.fromJson(Map<String, dynamic> json) {
    return DeclaredItem(
      id: json['id'] as int,
      label: json['label'] as String,
      photoUrl: json['photoUrl'] as String,
      confirmedReceived: json['confirmedReceived'] as bool? ?? false,
      discrepancyNote: json['discrepancyNote'] as String?,
    );
  }
}

/// The most recent payment attached to an order (for the receipt).
class OrderPayment {
  final int id;
  final double amount;
  final String status; // PENDING/SETTLED/FAILED/EXPIRED/CANCELLED
  final String? method;

  OrderPayment({
    required this.id,
    required this.amount,
    required this.status,
    this.method,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'PENDING',
      method: json['method'] as String?,
    );
  }
}

/// Minimal laundromat summary embedded on an order (location-safe).
class OrderLaundromat {
  final int id;
  final String name;
  final String? areaLabel;
  final String? imageUrl;

  OrderLaundromat({
    required this.id,
    required this.name,
    this.areaLabel,
    this.imageUrl,
  });

  factory OrderLaundromat.fromJson(Map<String, dynamic> json) {
    return OrderLaundromat(
      id: json['id'] as int,
      name: json['name'] as String,
      areaLabel: json['areaLabel'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class Order {
  final int id;
  final OrderStatus status;
  final String pricingModel; // 'PER_KG' or 'PER_ITEM'
  final String pickupAddress;
  final String deliveryAddress;
  final String? notes;

  final double? distanceKm;
  final double deliveryFee;
  final double? itemsSubtotal;
  final double? weighedKg;
  final double? finalTotal;
  final double voucherDiscount;

  final DateTime createdAt;
  final DateTime updatedAt;

  final OrderLaundromat? laundromat;
  final List<OrderItem> items;
  final List<DeclaredItem> declaredItems;
  final List<OrderPayment> payments;

  Order({
    required this.id,
    required this.status,
    required this.pricingModel,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.notes,
    this.distanceKm,
    required this.deliveryFee,
    this.itemsSubtotal,
    this.weighedKg,
    this.finalTotal,
    required this.voucherDiscount,
    required this.createdAt,
    required this.updatedAt,
    this.laundromat,
    required this.items,
    required this.declaredItems,
    required this.payments,
  });

  bool get isKilo => pricingModel == 'PER_KG';

  /// The most recent payment, if any.
  OrderPayment? get latestPayment => payments.isEmpty ? null : payments.first;

  /// Whether this order is currently in the customer's action queue.
  bool get needsWeightApproval =>
      status == OrderStatus.weighedAwaitingConfirm;

  factory Order.fromJson(Map<String, dynamic> json) {
    double? optDouble(dynamic v) => v == null ? null : (v as num).toDouble();

    return Order(
      id: json['id'] as int,
      status: orderStatusFromString((json['status'] ?? '') as String),
      pricingModel: json['pricingModel'] as String? ?? 'PER_ITEM',
      pickupAddress: json['pickupAddress'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      notes: json['notes'] as String?,
      distanceKm: optDouble(json['distanceKm']),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      itemsSubtotal: optDouble(json['itemsSubtotal']),
      weighedKg: optDouble(json['weighedKg']),
      finalTotal: optDouble(json['finalTotal']),
      voucherDiscount: (json['voucherDiscount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      laundromat: json['laundromat'] == null
          ? null
          : OrderLaundromat.fromJson(json['laundromat'] as Map<String, dynamic>),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      declaredItems: (json['declaredItems'] as List? ?? [])
          .map((e) => DeclaredItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((e) => OrderPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
