import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class WalkForm extends StatelessWidget {
  final int walkDuration;
  final ValueChanged<int> onDurationChanged;
  final String selectedIntensity;
  final ValueChanged<String> onIntensityChanged;

  const WalkForm({
    super.key,
    required this.walkDuration,
    required this.onDurationChanged,
    required this.selectedIntensity,
    required this.onIntensityChanged,
  });

  static const List<String> intensityOptions = ['가벼움', '보통', '격렬함'];

  // ✔ 카테고리별 색상 사용
  Color get _accent => kCategoryColorMap['walk']!;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 산책 시간
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white, // ✅ 안쪽 흰색
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: _accent.withOpacity(0.15), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '산책 시간',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: walkDuration.toDouble(),
                      min: 5,
                      max: 300,
                      divisions: 59,
                      activeColor: _accent,
                      onChanged: (value) => onDurationChanged(value.round()),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '$walkDuration분',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // 산책 강도
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white, // 안쪽 흰색
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: _accent.withOpacity(0.15), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '산책 강도',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: intensityOptions.map((intensity) {
                  final isSelected = selectedIntensity == intensity;
                  return Material(
                    color: isSelected ? _accent : Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(color: _accent, width: 1.0),
                    ),
                    child: InkWell(
                      onTap: () => onIntensityChanged(intensity),
                      customBorder: const StadiumBorder(),
                      child: Center(
                        child: Text(
                          intensity,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _accent,
                            fontWeight: FontWeight.w600,
                          ),
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
