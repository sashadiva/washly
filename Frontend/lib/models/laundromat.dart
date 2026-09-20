class Laundromat {
  final int id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  final String? imageUrl;
  final List<String> tags;

  Laundromat({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    this.distanceKm,
    this.imageUrl,
    required this.tags,
  });

  factory Laundromat.fromJson(Map<String, dynamic> json) {
    return Laundromat(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'],
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}