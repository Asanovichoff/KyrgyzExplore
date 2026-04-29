class BookingModel {
  const BookingModel({
    required this.id,
    required this.listingId,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nightCount,
    required this.totalPrice,
    required this.createdAt,
    this.guestMessage,
  });

  final String id;
  final String listingId;
  final String status; // PENDING | CONFIRMED | REJECTED | CANCELLED | PAID
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nightCount;
  final double totalPrice;
  final String? guestMessage;
  final DateTime createdAt;

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        listingId: json['listingId'] as String,
        status: json['status'] as String,
        checkInDate: DateTime.parse(json['checkInDate'] as String),
        checkOutDate: DateTime.parse(json['checkOutDate'] as String),
        nightCount: (json['nightCount'] as num).toInt(),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        guestMessage: json['guestMessage'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
