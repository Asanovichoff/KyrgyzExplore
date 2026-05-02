class PaymentIntentModel {
  const PaymentIntentModel({
    required this.clientSecret,
    required this.publishableKey,
    required this.totalPrice,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) =>
      PaymentIntentModel(
        clientSecret: json['clientSecret'] as String,
        publishableKey: json['publishableKey'] as String,
        totalPrice: (json['totalPrice'] as num).toDouble(),
      );

  final String clientSecret;
  final String publishableKey;
  final double totalPrice;
}
