import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:APP/widget/app_font.dart';

import 'api/insurance_detail_api.dart';
import 'models/insurance_detail_model.dart';

const kLavender     = Color(0xFFF5F2F8); // 연한 보라
const kLavenderLine = Color(0xFFE5D4FF);
const kTextPrimary  = Colors.black;
const kTextMuted    = Color(0xFF6B7280);

class InsuranceDetailPage extends StatefulWidget {
  const InsuranceDetailPage({
    super.key,
    required this.productUuid,
    this.initialCompany,
    this.initialProduct,
    this.initialImageUrl,
  });

  final String productUuid;
  final String? initialCompany;
  final String? initialProduct;
  final String? initialImageUrl;

  @override
  State<InsuranceDetailPage> createState() => _InsuranceDetailPageState();
}

class _InsuranceDetailPageState extends State<InsuranceDetailPage> {
  late Future<PetInsuranceDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = InsuranceDetailApi.instance.fetchDetail(widget.productUuid);
  }

  Future<void> _reload() async {
    setState(() {
      _future = InsuranceDetailApi.instance.fetchDetail(widget.productUuid);
    });
    await _future;
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // 화이트 카드
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLavenderLine),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // 라벤더 박스(섹션 컨테이너)
  Widget _lavenderBox({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kLavender,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLavenderLine),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // 섹션: 라벤더 → 내부 화이트 카드
  Widget _lavenderSectionWithInnerCard(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return _lavenderBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFont(title, size: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
          const SizedBox(height: 12),
          _card(child: AppFont(body, size: 13, color: kTextPrimary)),
        ],
      ),
    );
  }

  // 칩
  Widget _pill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kLavenderLine),
      ),
      child: AppFont(text, size: 12, color: kTextPrimary, fontWeight: FontWeight.w700),
    );
  }

  Widget _pillsLine(List<Widget> pills) {
    if (pills.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: pills),
      ),
    );
  }

  Widget _kvRow(String k, String v, {double keyWidth = 120}) {
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: keyWidth, child: AppFont(k, size: 12, color: kTextMuted, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(child: AppFont(v, size: 13, color: kTextPrimary)),
        ],
      ),
    );
  }

  // 헤더(카드 X)
  Widget _header({String? img, String? company, String? name, List<Widget> pills = const []}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 96,
            child: (img != null && img.isNotEmpty)
                ? Image.network(img, fit: BoxFit.cover)
                : Container(color: Colors.white, child: const Icon(Icons.pets, color: Color(0xFF6B21A8))),
          ),
        ),
        const SizedBox(height: 12),
        AppFont(company ?? '', size: 12, color: kTextPrimary, fontWeight: FontWeight.w600),
        const SizedBox(height: 6),
        AppFont(name ?? '', size: 20, fontWeight: FontWeight.w900, color: kTextPrimary),
        const SizedBox(height: 12),
        _pillsLine(pills),
      ],
    );
  }

  Widget _joinInfo(PetInsuranceDetail d) {
    return _lavenderBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFont('가입 정보', size: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.targetAnimal.isNotEmpty) _pill('대상 ${d.targetAnimal}'),
              if (d.maxRenewalAge.isNotEmpty) _pill('최대 갱신연령 ${d.maxRenewalAge}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planCard(InsurancePlan p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFont(p.planName, size: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
          const SizedBox(height: 12),
          _kvRow('연간 한도', p.annualMedicalLimit),
          _kvRow('1일 한도(비수술)', p.dailyLimitNonSurgery),
          _kvRow('1일 한도(수술)', p.dailyLimitSurgery),
          _kvRow('자기부담금', p.deductible),
          _kvRow('보상비율', p.reimbursementRate),
          _kvRow('책임한도', p.liabilityLimit),
        ],
      ),
    );
  }

  // “상품 페이지” 등 버튼은 카드 없이
  Widget _actions(PetInsuranceDetail d) {
    if (d.productUrl.isEmpty && d.productPdf.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    if (d.productUrl.isNotEmpty) {
      children.add(
        ElevatedButton.icon(
          onPressed: () => _openUrl(d.productUrl),
          icon: const Icon(Icons.open_in_new, color: kTextPrimary),
          label: const Text('상품 페이지', style: TextStyle(color: kTextPrimary)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE9D5FF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: const StadiumBorder(),
            side: const BorderSide(color: Color(0xFFBFA7FF), width: 1),
          ),
        ),
      );
    }
    if (d.productPdf.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        OutlinedButton.icon(
          onPressed: () => _openUrl(d.productPdf),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('상품설명서(PDF)'),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            side: const BorderSide(color: kLavenderLine),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children.map((w) => Center(child: w)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget centerWrap(Widget child) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: const AppFont('반려동물 보험 상세', size: 18, fontWeight: FontWeight.bold),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<PetInsuranceDetail>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  centerWrap(_header(
                    img: widget.initialImageUrl,
                    company: widget.initialCompany ?? '',
                    name: widget.initialProduct ?? '',
                  )),
                  const SizedBox(height: 16),
                  _card(child: const LinearProgressIndicator()),
                  const SizedBox(height: 80),
                ],
              );
            }

            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                children: [
                  centerWrap(_card(
                    child: Column(
                      children: const [
                        Icon(Icons.error_outline, size: 36),
                        SizedBox(height: 12),
                        AppFont('상세 정보를 불러오지 못했습니다.', size: 16, fontWeight: FontWeight.bold),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  centerWrap(OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  )),
                  const SizedBox(height: 80),
                ],
              );
            }

            final d = snap.data!;
            final pills = <Widget>[
              if (d.targetAnimal.isNotEmpty) _pill('대상 ${d.targetAnimal}'),
              if (d.maxRenewalAge.isNotEmpty) _pill('갱신 ${d.maxRenewalAge}'),
            ];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                centerWrap(_header(img: d.companyImg, company: d.companyName, name: d.productName, pills: pills)),
                const SizedBox(height: 12),

                centerWrap(_lavenderSectionWithInnerCard('요약', d.summary)),
                const SizedBox(height: 12),
                centerWrap(_lavenderSectionWithInnerCard('특징', d.productFeature)),
                const SizedBox(height: 12),
                centerWrap(_lavenderSectionWithInnerCard('상세 안내', d.detail)),
                const SizedBox(height: 12),

                centerWrap(_joinInfo(d)),
                const SizedBox(height: 12),

                if (d.plans.isNotEmpty) ...[
                  centerWrap(_lavenderBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppFont('플랜 구성', size: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
                        const SizedBox(height: 12),
                        ...d.plans.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _planCard(p),
                        )),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ] else
                  centerWrap(_lavenderBox(
                    child: const AppFont('플랜 정보가 없습니다.', size: 13, color: Color(0xFF42464D)),
                  )),

                centerWrap(_actions(d)),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
}
