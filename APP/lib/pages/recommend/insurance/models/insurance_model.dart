class InsuranceProduct {
  final String productUuid;
  final String companyName;
  final String companyImg;
  final String productName;
  final String summary;
  final String productFeature;
  final String targetAnimal;
  final String maxRenewalAge;
  final List<String> plans;

  InsuranceProduct({
    required this.productUuid,
    required this.companyName,
    required this.companyImg,
    required this.productName,
    required this.summary,
    required this.productFeature,
    required this.targetAnimal,
    required this.maxRenewalAge,
    required this.plans,
  });

  factory InsuranceProduct.fromJson(Map<String, dynamic> j) => InsuranceProduct(
        productUuid: (j['product_uuid'] ?? '').toString(),
        companyName: (j['company_name'] ?? '').toString(),
        companyImg: (j['company_img'] ?? '').toString(),
        productName: (j['product_name'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        productFeature: (j['product_feature'] ?? '').toString(),
        targetAnimal: (j['target_animal'] ?? '').toString(),
        maxRenewalAge: (j['max_renewal_age'] ?? '').toString(),
        plans: (j['plans'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
