class CartItem {
  final int serviceId;
  final String serviceName;
  final bool isKilo;
  final double unitPrice;
  int quantity;
  String? notes;

  CartItem({
    required this.serviceId,
    required this.serviceName,
    required this.isKilo,
    required this.unitPrice,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => unitPrice * quantity;
}