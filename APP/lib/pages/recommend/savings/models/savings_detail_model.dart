class SavingsDetail {
  final String companyName;
  final String companyImg;
  final String productName;
  final String productUrl;
  final String productPdf;
  final String summary;
  final String detail;
  final String productFeature;
  final String targetAudience;
  final String subscriptionPeriodMonths;
  final String minMonthlyAmount;
  final String maxMonthlyAmount;
  final String depositType;
  final String baseInterestRate;
  final String maxInterestRate;
  final String preferentialConditions;
  final String interestPaymentMethod;
  final String additionalBenefits;
  final String isActive;
  final String createdAt;
  final String updatedAt;

  SavingsDetail({
    required this.companyName,
    required this.companyImg,
    required this.productName,
    required this.productUrl,
    required this.productPdf,
    required this.summary,
    required this.detail,
    required this.productFeature,
    required this.targetAudience,
    required this.subscriptionPeriodMonths,
    required this.minMonthlyAmount,
    required this.maxMonthlyAmount,
    required this.depositType,
    required this.baseInterestRate,
    required this.maxInterestRate,
    required this.preferentialConditions,
    required this.interestPaymentMethod,
    required this.additionalBenefits,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavingsDetail.fromJson(Map<String, dynamic> j) => SavingsDetail(
        companyName: (j['company_name'] ?? '').toString(),
        companyImg: (j['company_img'] ?? '').toString(),
        productName: (j['product_name'] ?? '').toString(),
        productUrl: (j['product_url'] ?? '').toString(),
        productPdf: (j['product_pdf'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        detail: (j['detail'] ?? '').toString(),
        productFeature: (j['product_feature'] ?? '').toString(),
        targetAudience: (j['target_audience'] ?? '').toString(),
        subscriptionPeriodMonths: (j['subscription_period_months'] ?? '').toString(),
        minMonthlyAmount: (j['min_monthly_amount'] ?? '').toString(),
        maxMonthlyAmount: (j['max_monthly_amount'] ?? '').toString(),
        depositType: (j['deposit_type'] ?? '').toString(),
        baseInterestRate: (j['base_interest_rate'] ?? '').toString(),
        maxInterestRate: (j['max_interest_rate'] ?? '').toString(),
        preferentialConditions: (j['preferential_conditions'] ?? '').toString(),
        interestPaymentMethod: (j['interest_payment_method'] ?? '').toString(),
        additionalBenefits: (j['additional_benefits'] ?? '').toString(),
        isActive: (j['is_active'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
        updatedAt: (j['updated_at'] ?? '').toString(),
      );
}
