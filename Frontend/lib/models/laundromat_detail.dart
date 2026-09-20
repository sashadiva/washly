import 'laundry_service_item.dart';
import 'review.dart';

class LaundromatDetail {
  final int id;
  final String name;
  final String? description;
  final String address;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final List<String> tags;
  final List<LaundryServiceItem> services;
  final List<ReviewItem> reviews;

  LaundromatDetail({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.rating,
    required this.reviewCount,
    this.imageUrl,
    required this.tags,
    required this.services,
    required this.reviews,
  });

  factory LaundromatDetail.fromJson(Map<String, dynamic> json) {
    return LaundromatDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      services: (json['services'] as List? ?? [])
          .map((s) => LaundryServiceItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => ReviewItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}