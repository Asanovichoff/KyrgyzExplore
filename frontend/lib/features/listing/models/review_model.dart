class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.travelerName,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        travelerName: json['travelerName'] as String? ?? 'Traveler',
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String travelerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}
