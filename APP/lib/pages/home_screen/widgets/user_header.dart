import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';

/// 사용자 헤더 위젯 - 최적화된 사용자 인터페이스
///
/// **성능 최적화:**
/// - const 생성자로 불필요한 위젯 재생성 방지
/// - StatelessWidget으로 불변 UI 컴포넌트 구현
/// - 콜백 기반 이벤트 처리로 결합도 최소화
class UserHeader extends StatelessWidget {
  final VoidCallback onRecordPressed;

  const UserHeader({
    required this.onRecordPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: primaryColor,
            child: Icon(Icons.person, color: Colors.white),
          ),
          Spacer(),
          TextButton.icon(
            onPressed: onRecordPressed,
            icon: const Icon(Icons.edit, color: Colors.black87, size: 18),
            label: const Text('기록하기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surfaceCard,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
    );
  }
}