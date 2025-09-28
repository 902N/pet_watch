import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:APP/widget/app_font.dart';
import 'api/savings_detail_api.dart';
import 'models/savings_detail_model.dart';

/// 보험 상세와 동일 팔레트
const kLavender     = Color(0xFFF5F2F8); // 라벤더 배경
const kLavenderLine = Color(0xFFE5D4FF); // 라벤더 보더
const kTextPrimary  = Colors.black;
const kTextSecondary = Color(0xFF42464D);

class SavingsDetailPage extends StatefulWidget {
  const SavingsDetailPage({
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
  State<SavingsDetailPage> createState() => _SavingsDetailPageState();
}

class _SavingsDetailPageState extends State<SavingsDetailPage> {
  late Future<SavingsDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = SavingsDetailApi.instance.fetchDetail(widget.productUuid);
  }

  Future<void> _reload() async {
    setState(() {
      _future = SavingsDetailApi.instance.fetchDetail(widget.productUuid);
    });
    await _future;
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 내부 화이트 카드 (라벤더 섹션 안에서 사용)
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

  /// 라벤더 섹션 컨테이너
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

  /// (요약/특징/상세 안내) = 라벤더 섹션 + 내부 화이트 카드
  Widget _lavenderSectionWithInnerCard(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return _lavenderBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFont(title, size: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
          const SizedBox(height: 12),
          _card(child: AppFont(body, size: 13, color: kTextSecondary)),
        ],
      ),
    );
  }

  /// 칩(금리 표시)
  Widget _pill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kLavenderLine),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary),
      ),
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

  /// 헤더(카드 X)
  Widget _header({
    String? img,
    String? company,
    String? name,
    String? baseRate,
    String? maxRate,
  }) {
    final pills = <Widget>[
      if (baseRate != null && baseRate.isNotEmpty) _pill('# 기본 ${baseRate}%'),
      if (maxRate != null && maxRate.isNotEmpty) _pill('# 최대 ${maxRate}%'),
    ];
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
                : Container(
              color: Colors.white,
              child: const Icon(Icons.account_balance, color: Color(0xFF6B21A8)),
            ),
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

  /// 가입 정보 = 라벤더 섹션 + 내부 화이트 카드(행 리스트)
  Widget _joinInfoCard(SavingsDetail d) {
    Widget _row(String title, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextPrimary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: kTextSecondary))),
          ],
        ),
      );
    }

    return _lavenderBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFont('가입 정보', size: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('가입대상', d.targetAudience),
                _row('가입기간(개월)', d.subscriptionPeriodMonths),
                _row('월 납입 최소', d.minMonthlyAmount),
                _row('월 납입 최대', d.maxMonthlyAmount),
                _row('예금 유형', d.depositType),
                _row('이자 지급 방식', d.interestPaymentMethod),
                _row('우대조건', d.preferentialConditions),
                _row('추가 혜택', d.additionalBenefits),
                _row('판매 상태', d.isActive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼(둘 다 채워진 연보라 버튼으로 통일)
  Widget _actions(SavingsDetail d) {
    final widgets = <Widget>[];
    ButtonStyle filled = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE9D5FF),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: const StadiumBorder(),
      side: const BorderSide(color: Color(0xFFBFA7FF), width: 1),
      foregroundColor: kTextPrimary,
    );

    if (d.productUrl.isNotEmpty) {
      widgets.add(
        ElevatedButton.icon(
          onPressed: () => _openUrl(d.productUrl),
          icon: const Icon(Icons.open_in_new),
          label: const Text('상품 페이지'),
          style: filled,
        ),
      );
    }
    if (d.productPdf.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
      widgets.add(
        ElevatedButton.icon(
          onPressed: () => _openUrl(d.productPdf),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('상품설명서(PDF)'),
          style: filled,
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widgets.map((w) => Padding(padding: const EdgeInsets.only(top: 8), child: w)).toList(),
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
        shadowColor: Colors.transparent,
        title: const AppFont('적금 상품 상세', size: 18, fontWeight: FontWeight.bold),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<SavingsDetail>(
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
                  centerWrap(
                    OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
                  ),
                  const SizedBox(height: 80),
                ],
              );
            }

            final d = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                // 헤더 (카드 X)
                centerWrap(_header(
                  img: d.companyImg,
                  company: d.companyName,
                  name: d.productName,
                  baseRate: d.baseInterestRate,
                  maxRate: d.maxInterestRate,
                )),
                const SizedBox(height: 12),

                // 섹션들: 라벤더 + 내부 화이트 카드
                centerWrap(_lavenderSectionWithInnerCard('요약', d.summary)),
                const SizedBox(height: 12),
                centerWrap(_lavenderSectionWithInnerCard('특징', d.productFeature)),
                const SizedBox(height: 12),
                centerWrap(_lavenderSectionWithInnerCard('상세 안내', d.detail)),
                const SizedBox(height: 12),

                // 가입 정보: 라벤더 섹션 + 내부 화이트 카드
                centerWrap(_joinInfoCard(d)),
                const SizedBox(height: 16),

                // 액션 버튼(둘 다 채워진 연보라)
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
