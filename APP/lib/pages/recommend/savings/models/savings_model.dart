  class SavingsProduct {
  final String productUuid;
  final String companyName;
  final String companyImg;
  final String productName;
  final String summary;
  final String productFeature;
  final String baseInterestRate;
  final String maxInterestRate;

  SavingsProduct({
    required this.productUuid,
    required this.companyName,
    required this.companyImg,
    required this.productName,
    required this.summary,
    required this.productFeature,
    required this.baseInterestRate,
    required this.maxInterestRate,
  });

  factory SavingsProduct.fromJson(Map<String, dynamic> j) => SavingsProduct(
        productUuid: (j['product_uuid'] ?? '').toString(),
        companyName: (j['company_name'] ?? '').toString(),
        companyImg: (j['company_img'] ?? '').toString(),
        productName: (j['product_name'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        productFeature: (j['product_feature'] ?? '').toString(),
        baseInterestRate: (j['base_interest_rate'] ?? '').toString(),
        maxInterestRate: (j['max_interest_rate'] ?? '').toString(),
      );
}
