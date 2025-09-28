class AiRecommendation {
  final String productName;
  final String reason;

  AiRecommendation({
    required this.productName,
    required this.reason,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {

    return AiRecommendation(
      productName: json['recommend_product_name'] as String? ?? '',
      // backend 잘못
      reason: json['recommend_reseon'] as String? ?? '',
    );
  }
}
