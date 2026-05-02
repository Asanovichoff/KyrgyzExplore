class PresignModel {
  const PresignModel({required this.uploadUrl, required this.s3Key});
  final String uploadUrl;
  final String s3Key;
}

class CreateListingData {
  const CreateListingData({
    required this.type,
    required this.title,
    required this.description,
    required this.pricePerUnit,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    this.currency = 'KGS',
    this.maxGuests,
  });

  final String type;
  final String title;
  final String description;
  final double pricePerUnit;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String currency;
  final int? maxGuests;

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'description': description,
        'pricePerUnit': pricePerUnit,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'currency': currency,
        if (maxGuests != null) 'maxGuests': maxGuests,
      };
}
