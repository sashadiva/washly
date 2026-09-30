// Warranty claim models, mirroring the backend claim endpoints.

class ClaimDeclaredItem {
  final int id;
  final String label;
  final bool confirmedReceived;

  ClaimDeclaredItem({
    required this.id,
    required this.label,
    required this.confirmedReceived,
  });

  factory ClaimDeclaredItem.fromJson(Map<String, dynamic> json) {
    return ClaimDeclaredItem(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      confirmedReceived: json['confirmedReceived'] as bool? ?? false,
    );
  }
}

class WarrantyClaim {
  final int id;
  final int orderId;
  final int declaredItemId;
  final String description;
  final List<String> photoUrls;
  final String status; // SUBMITTED/APPROVED/REJECTED/RESOLVED
  final String? resolutionNote;
  final double? payoutAmount;
  final String? payoutFundedBy;
  final ClaimDeclaredItem? declaredItem;

  WarrantyClaim({
    required this.id,
    required this.orderId,
    required this.declaredItemId,
    required this.description,
    required this.photoUrls,
    required this.status,
    this.resolutionNote,
    this.payoutAmount,
    this.payoutFundedBy,
    this.declaredItem,
  });

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) {
    return WarrantyClaim(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      declaredItemId: json['declaredItemId'] as int,
      description: json['description'] as String? ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      status: json['status'] as String? ?? 'SUBMITTED',
      resolutionNote: json['resolutionNote'] as String?,
      payoutAmount: (json['payoutAmount'] as num?)?.toDouble(),
      payoutFundedBy: json['payoutFundedBy'] as String?,
      declaredItem: json['declaredItem'] == null
          ? null
          : ClaimDeclaredItem.fromJson(
              json['declaredItem'] as Map<String, dynamic>),
    );
  }
}
