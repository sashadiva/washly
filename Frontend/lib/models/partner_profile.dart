// Partner-facing shop profile (the partner sees their own exact address/coords,
// unlike the customer-facing mapper). Mirrors GET /api/partner/profile.

class PartnerProfile {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String? areaLabel;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final List<String> specialties;

  PartnerProfile({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.areaLabel,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.specialties = const [],
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String? ?? '',
      areaLabel: json['areaLabel'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isOpen: json['isOpen'] as bool? ?? true,
      specialties: List<String>.from(json['specialties'] ?? []),
    );
  }
}

/// A partner's editable service. Reuses the PricingUnit string ('PER_KG'/'PER_ITEM').
class ShopService {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final String? imageUrl;

  ShopService({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.unit,
    this.imageUrl,
  });

  bool get isKilo => unit == 'PER_KG';

  factory ShopService.fromJson(Map<String, dynamic> json) {
    return ShopService(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'PER_ITEM',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// Sales dashboard summary from GET /api/partner/dashboard.
class PartnerDashboard {
  final double revenue;
  final int paidOrderCount;
  final int totalOrderCount;
  final int completedOrderCount;

  PartnerDashboard({
    required this.revenue,
    required this.paidOrderCount,
    required this.totalOrderCount,
    required this.completedOrderCount,
  });

  factory PartnerDashboard.fromJson(Map<String, dynamic> json) {
    return PartnerDashboard(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      paidOrderCount: json['paidOrderCount'] as int? ?? 0,
      totalOrderCount: json['totalOrderCount'] as int? ?? 0,
      completedOrderCount: json['completedOrderCount'] as int? ?? 0,
    );
  }
}
