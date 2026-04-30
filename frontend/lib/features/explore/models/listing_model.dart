class ListingImageModel {
  const ListingImageModel({
    required this.id,
    required this.url,
    required this.displayOrder,
  });

  factory ListingImageModel.fromJson(Map<String, dynamic> json) =>
      ListingImageModel(
        id: json['id'] as String,
        url: json['url'] as String,
        displayOrder: (json['displayOrder'] as num).toInt(),
      );

  final String id;
  final String url;
  final int displayOrder;
}

class ListingModel {
  const ListingModel({
    required this.id,
    required this.hostId,
    required this.type,
    required this.title,
    required this.description,
    required this.pricePerUnit,
    required this.currency,
    required this.maxGuests,
    required this.reviewCount,
    required this.images,
    this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.averageRating,
    this.distanceKm,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) => ListingModel(
        id: json['id'] as String,
        hostId: json['hostId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 1,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        images: ((json['images'] as List<dynamic>?) ?? [])
            .map((e) => ListingImageModel.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        city: json['city'] as String?,
        country: json['country'] as String?,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        address: json['address'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      );

  final String id;
  final String hostId;
  final String type;
  final String title;
  final String description;
  final double pricePerUnit;
  final String currency;
  final int maxGuests;
  final int reviewCount;
  final List<ListingImageModel> images;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final double? averageRating;
  final double? distanceKm;

  String? get coverUrl => images.isNotEmpty ? images.first.url : null;
}
