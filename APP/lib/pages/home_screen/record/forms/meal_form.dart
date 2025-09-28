import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class MealForm extends StatelessWidget {
  final int amount;
  final ValueChanged<int> onAmountChanged;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final String selectedDetail;
  final ValueChanged<String> onDetailChanged;
  final TextEditingController? detailController;

  const MealForm({
    super.key,
    required this.amount,
    required this.onAmountChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedDetail,
    required this.onDetailChanged,
    this.detailController,
  });

  static const List<String> mealTypes = ['사료', '간식', '물', '기타'];
  
  static const Map<String, List<String>> detailOptionsByType = {
    '사료': ['건식', '습식', '생식', '처방', '동결', '반습'],
    '간식': ['육포', '쿠키', '껌류', '트릿', '치즈', '야채'],
    '물': ['생수', '미네랄', '기능수'],
    '기타': ['유제품', '보조제', '수프', '오일', '파우더', '특수식'],
  };
  
  List<String> _getDetailOptions() {
    return detailOptionsByType[selectedType] ?? detailOptionsByType['사료']!;
  }

  Color get _accent => kCategoryColorMap['meal']!;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          accent: _accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(text: '급여량 (g)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accent,
                        inactiveTrackColor: _accent.withOpacity(0.2),
                        thumbColor: _accent,
                        overlayColor: _accent.withOpacity(0.15),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: amount.toDouble(),
                        min: 10,
                        max: 500,
                        divisions: 49,
                        label: '${amount}g',
                        onChanged: (v) => onAmountChanged(v.round()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [_accent.withOpacity(0.95), _accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${amount}g',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          accent: _accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(text: '사료 종류'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.4,
                children: mealTypes.map((t) {
                  final sel = selectedType == t;
                  return _ChoicePill(
                    label: t,
                    selected: sel,
                    accent: _accent,
                    onTap: () => onTypeChanged(t),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          accent: _accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(text: '상세 정보'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _getDetailOptions().map((detail) {
                  final isSelected = selectedDetail == detail;
                  return GestureDetector(
                    onTap: () => onDetailChanged(detail),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: _accent, width: 1.0),
                      ),
                      child: Text(
                        detail,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? accent : accent.withOpacity(0.35), width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : accent,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color accent;

  const _Card({required this.child, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    );
  }
}
