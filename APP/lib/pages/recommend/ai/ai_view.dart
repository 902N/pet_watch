import 'package:flutter/material.dart';
import 'api/ai_recommend_api.dart';
import 'models/ai_recommend.dart';

class AiRecommendSheet extends StatefulWidget {
  const AiRecommendSheet({super.key});

  @override
  State<AiRecommendSheet> createState() => _AiRecommendSheetState();
}

class _AiRecommendSheetState extends State<AiRecommendSheet> {
  late final Future<AiRecommendation> _future;

  @override
  void initState() {
    super.initState();
    _future = AiRecommendApi().fetch();
  }

  // ───────────────────── 줄바꿈 보조 유틸 ─────────────────────

  /// 아주 긴 토큰(URL/영문연속 등)을 안전하게 끊을 수 있도록 ZWSP 삽입
  String _enableBreakForLongTokens(String s) {
    return s
        .replaceAll('/', '/\u200B')
        .replaceAll('-', '-\u200B')
        .replaceAll('_', '_\u200B')
        .replaceAll('.', '.\u200B');
  }

  /// 한글/영문/숫자로 이루어진 연속 토큰 내부에서는 개행이 일어나지 않도록
  /// 문자 사이에 WORD JOINER(\u2060) 삽입 → 단어 단위로만 줄바꿈
  String _noMidWordBreak(String s) {
    final out = StringBuffer();
    final runes = s.runes.toList();

    bool joinable(int r) =>
        (r >= 0xAC00 && r <= 0xD7A3) || // 한글
            (r >= 0x0030 && r <= 0x0039) || // 숫자
            (r >= 0x0041 && r <= 0x005A) || // A-Z
            (r >= 0x0061 && r <= 0x007A);   // a-z

    for (int i = 0; i < runes.length; i++) {
      final cur = runes[i];
      out.writeCharCode(cur);
      if (i + 1 < runes.length) {
        final next = runes[i + 1];
        if (joinable(cur) && joinable(next)) out.write('\u2060');
      }
    }
    return out.toString();
  }

  String _formatBody(String text) {
    return _enableBreakForLongTokens(_noMidWordBreak(text));
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀 + 닫기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "AI 맞춤 금융상품 추천",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<AiRecommendation>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snap.hasError) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2ECFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5D4FF)),
                          ),
                          child: Text(
                            _formatBody('추천 불러오기에 실패했습니다.\n${snap.error}'),
                            softWrap: true,
                            maxLines: null,
                            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
                          ),
                        );
                      }

                      final data = snap.data!;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2ECFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5D4FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 본문 설명
                            Text(
                              _formatBody(data.reason),
                              softWrap: true,
                              maxLines: null,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE5D4FF)),
                            const SizedBox(height: 10),

                            // ▼ 여기부터 중앙 정렬 + 진한 검정
                            const Center(
                              child: Text(
                                "추천 상품",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: 상세 페이지 이동
                                },
                                child: Text(
                                  _formatBody(data.productName),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: null,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black, // ← 진한 검정
                                  ),
                                ),
                              ),
                            ),
                            // ▲ 중앙 정렬 + 검정 굵게
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
