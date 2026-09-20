class ReviewItem {
  final int id;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime createdAt;

  ReviewItem({
    required this.id,
    required this.rating,
    this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      userName: json['userName'] ?? 'Customer',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}