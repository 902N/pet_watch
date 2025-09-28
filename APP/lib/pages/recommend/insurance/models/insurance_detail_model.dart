class PetInsuranceDetail {
  final String companyName;
  final String companyImg;
  final String productName;
  final String productUrl;
  final String productPdf;
  final String summary;
  final String detail;
  final String productFeature;
  final String targetAnimal;
  final String maxRenewalAge;
  final List<InsurancePlan> plans;

  PetInsuranceDetail({
    required this.companyName,
    required this.companyImg,
    required this.productName,
    required this.productUrl,
    required this.productPdf,
    required this.summary,
    required this.detail,
    required this.productFeature,
    required this.targetAnimal,
    required this.maxRenewalAge,
    required this.plans,
  });

  factory PetInsuranceDetail.fromJson(Map<String, dynamic> j) {
    final planList = (j['plans'] as List<dynamic>? ?? [])
        .map((e) => InsurancePlan.fromJson(e as Map<String, dynamic>))
        .toList();

    return PetInsuranceDetail(
      companyName: (j['company_name'] ?? '').toString(),
      companyImg: (j['company_img'] ?? '').toString(),
      productName: (j['product_name'] ?? '').toString(),
      productUrl: (j['product_url'] ?? '').toString(),
      productPdf: (j['product_pdf'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
      detail: (j['detail'] ?? '').toString(),
      productFeature: (j['product_feature'] ?? '').toString(),
      targetAnimal: (j['target_animal'] ?? '').toString(),
      maxRenewalAge: (j['max_renewal_age'] ?? '').toString(),
      plans: planList,
    );
  }
}

class InsurancePlan {
  final String planName;
  final String annualMedicalLimit;
  final String dailyLimitNonSurgery;
  final String dailyLimitSurgery;
  final String deductible;
  final String reimbursementRate;
  final String liabilityLimit;

  InsurancePlan({
    required this.planName,
    required this.annualMedicalLimit,
    required this.dailyLimitNonSurgery,
    required this.dailyLimitSurgery,
    required this.deductible,
    required this.reimbursementRate,
    required this.liabilityLimit,
  });

  factory InsurancePlan.fromJson(Map<String, dynamic> j) => InsurancePlan(
        planName: (j['plan_name'] ?? '').toString(),
        annualMedicalLimit: (j['annual_medical_limit'] ?? '').toString(),
        dailyLimitNonSurgery:
            (j['daily_limit_non_surgery'] ?? '').toString(),
        dailyLimitSurgery: (j['daily_limit_surgery'] ?? '').toString(),
        deductible: (j['deductible'] ?? '').toString(),
        reimbursementRate: (j['reimbursement_rate'] ?? '').toString(),
        liabilityLimit: (j['liability_limit'] ?? '').toString(),
      );
}
