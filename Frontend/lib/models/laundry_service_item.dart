class LaundryServiceItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String unit; // 'PER_KG' or 'PER_ITEM'
  final String? imageUrl;

  LaundryServiceItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.unit,
    this.imageUrl,
  });

  bool get isKilo => unit == 'PER_KG';

  factory LaundryServiceItem.fromJson(Map<String, dynamic> json) {
    return LaundryServiceItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'PER_ITEM',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}