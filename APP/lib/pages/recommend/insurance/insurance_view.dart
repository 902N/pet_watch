import 'package:flutter/material.dart';
import 'package:APP/widget/app_font.dart';
import 'insurance_detail_view.dart';
import 'api/insurance_api.dart';
import 'models/insurance_model.dart';

const kLavender = Color(0xFFF5F2F8);
const kLavenderLine = Color(0xFFE5D4FF);

class InsuranceView extends StatefulWidget {
  const InsuranceView({super.key});
  @override
  State<InsuranceView> createState() => _InsuranceViewState();
}

class _InsuranceViewState extends State<InsuranceView> {
  late Future<List<InsuranceProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = InsuranceService.instance.fetchInsurance();
  }

  Future<void> _reload() async {
    setState(() {
      _future = InsuranceService.instance.fetchInsurance();
    });
    await _future;
  }

  // 강아지 상품만 필터(원하면 제거 가능)
  bool _supportsDog(String targetAnimal) {
    final t = targetAnimal.replaceAll(' ', '');
    if (t.isEmpty) return true;
    return t.contains('개') || t.contains('강아지') || t.toLowerCase().contains('dog');
  }

  // 칩: “최대 가입 연령 + 첫 번째 플랜명”만
  List<String> _pickTopChips(InsuranceProduct p) {
    final List<String> chips = [];
    if (p.maxRenewalAge.isNotEmpty) chips.add('최대 가입 연령 ${p.maxRenewalAge}');
    final String plan = p.plans
        .map((e) => e.toString().trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (plan.isNotEmpty) chips.add(plan);
    return chips.take(2).toList();
  }

  Widget _tagChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kLavenderLine),
      ),
      child: AppFont(text, size: 12, color: Colors.black, fontWeight: FontWeight.w600),
    );
  }

  Widget _chipsLine(List<String> chips) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map(_tagChip).toList()),
      ),
    );
  }

  Widget _cardWrapper({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kLavender,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLavenderLine),
        ),
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  Widget _tile(BuildContext context, InsuranceProduct p) {
    final chips = _pickTopChips(p);
    return _cardWrapper(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InsuranceDetailPage(
              productUuid: p.productUuid,
              initialCompany: p.companyName,
              initialProduct: p.productName,
              initialImageUrl: p.companyImg,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (p.companyImg.isNotEmpty)
                  ? Image.network(p.companyImg, fit: BoxFit.cover)
                  : Container(color: Colors.white, child: const Icon(Icons.shield_outlined, color: Color(0xFF6B21A8))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                AppFont(p.companyName, size: 12, color: Colors.black, fontWeight: FontWeight.w700),
                const SizedBox(height: 6),
                AppFont(p.productName, size: 18, fontWeight: FontWeight.w800, color: Colors.black),
                const SizedBox(height: 10),
                _chipsLine(chips),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flatTheme = Theme.of(context).copyWith(shadowColor: Colors.transparent);
    return Theme(
      data: flatTheme,
      child: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<InsuranceProduct>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                children: [
                  const Icon(Icons.error_outline, size: 36),
                  const SizedBox(height: 12),
                  const AppFont('보험 상품을 불러오지 못했습니다.', size: 16, fontWeight: FontWeight.bold),
                  const SizedBox(height: 6),
                  AppFont('${snap.error}', size: 12, color: Color(0xFF878B93)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
                ],
              );
            }

            var items = (snap.data ?? []).where((p) => _supportsDog(p.targetAnimal)).toList();

            if (items.isEmpty) {
              return LayoutBuilder(
                builder: (ctx, c) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight - 48),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.black),
                            SizedBox(height: 12),
                            AppFont('표시할 보험 상품이 없습니다.', size: 16, fontWeight: FontWeight.bold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemBuilder: (context, i) => _tile(context, items[i]),
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemCount: items.length,
            );
          },
        ),
      ),
    );
  }
}
