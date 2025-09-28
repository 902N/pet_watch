import 'package:flutter/material.dart';
import 'package:APP/widget/app_font.dart';
import 'savings_detail_view.dart';
import 'models/savings_model.dart';
import 'api/savings_api.dart';

// ---- Lavender palette (통일)
const kLavender     = Color(0xFFF5F2F8); // ← 배경색을 #F5F2F8 로 변경
const kLavenderLine = Color(0xFFE5D4FF); // 테두리(그대로)

class SavingsView extends StatefulWidget {
  const SavingsView({super.key});
  @override
  State<SavingsView> createState() => _SavingsViewState();
}

class _SavingsViewState extends State<SavingsView> {
  late Future<List<SavingsProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = SavingsService.instance.fetchSavings();
  }

  Future<void> _reload() async {
    setState(() => _future = SavingsService.instance.fetchSavings());
    await _future;
  }

  String _trimRate(String r) {
    var t = r.trim();
    if (t.endsWith('%')) t = t.substring(0, t.length - 1);
    return t;
  }

  List<String> _chips(SavingsProduct p) {
    final List<String> res = [];
    if (p.baseInterestRate.isNotEmpty) res.add('기본 ${_trimRate(p.baseInterestRate)}%');
    if (p.maxInterestRate.isNotEmpty) res.add('최대 ${_trimRate(p.maxInterestRate)}%');
    // res.add('AI추천'); // 필요 시 사용
    return res;
  }

  Widget _tagChip(String text) {
    final isAi = text.replaceAll(' ', '').contains('AI추천');
    final Color bg = isAi ? const Color(0xFFF2F4F7) : Colors.white;
    final Color border = isAi ? const Color(0xFFE5E7EB) : kLavenderLine;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
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
    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent, // 틴트 제거(중요)
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: kLavender, // 통일 색상
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLavenderLine),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, SavingsProduct p) {
    final chips = _chips(p);
    return _cardWrapper(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SavingsDetailPage(
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
              child: p.companyImg.isNotEmpty
                  ? Image.network(p.companyImg, fit: BoxFit.cover)
                  : Container(color: Colors.white, child: const Icon(Icons.account_balance, color: Color(0xFF6B21A8))),
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
                const SizedBox(height: 8),
                AppFont(p.summary.isNotEmpty ? p.summary : p.productFeature, color: Colors.black, size: 13),
                const SizedBox(height: 12),
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
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<SavingsProduct>>(
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
                const AppFont('적금 상품을 불러오지 못했습니다.', size: 16, fontWeight: FontWeight.bold),
                const SizedBox(height: 6),
                AppFont('${snap.error}', size: 12, color: const Color(0xFF878B93)),
                const SizedBox(height: 16),
                OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
              ],
            );
          }

          final items = snap.data ?? [];
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
                          AppFont('표시할 적금 상품이 없습니다.', size: 16, fontWeight: FontWeight.bold),
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
    );
  }
}
