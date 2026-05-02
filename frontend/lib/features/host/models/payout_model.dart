class PayoutModel {
  const PayoutModel({
    required this.bookingId,
    required this.listingTitle,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalAmount,
    required this.paidAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) => PayoutModel(
        bookingId: json['bookingId'] as String,
        listingTitle: json['listingTitle'] as String,
        checkInDate: DateTime.parse(json['checkInDate'] as String),
        checkOutDate: DateTime.parse(json['checkOutDate'] as String),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paidAt: DateTime.parse(json['paidAt'] as String).toLocal(),
      );

  final String bookingId;
  final String listingTitle;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalAmount;
  final DateTime paidAt;

  int get nightCount => checkOutDate.difference(checkInDate).inDays;
}
