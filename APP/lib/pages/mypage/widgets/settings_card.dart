// lib/pages/mypage/widgets/settings_card.dart
import 'package:flutter/material.dart';
import 'settings_row.dart';
import 'package:APP/const/colors.dart';

class SettingsCard extends StatelessWidget {
  final bool loadingMe;
  final bool agreeNotification;
  final Future<void> Function() onFetchUser; // 누르면 바로 Dialog 띄우는 콜백
  final ValueChanged<bool> onTogglePush;
  final VoidCallback onLogout;   // 시그니처 유지 (미사용)
  final VoidCallback onWithdraw; // 시그니처 유지 (미사용)

  const SettingsCard({
    super.key,
    required this.loadingMe,
    required this.agreeNotification,
    required this.onFetchUser,
    required this.onTogglePush,
    required this.onLogout,
    required this.onWithdraw,
  });

  static const _line = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            '설정',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            // 푸시 알림 수신
            SettingsRow(
              left: Text(
                '푸시 알림 수신',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              right: Switch.adaptive(
                value: agreeNotification,
                onChanged: onTogglePush,
                activeColor: AppColors.primaryAccent,
              ),
            ),
            _sep(),
            // 계정 확인 — 바텀시트 호출 없이 Dialog만 띄움
            SettingsRow(
              left: Text(
                '계정 확인',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              right: loadingMe
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.chevron_right),
              onTap: () => onFetchUser(), // 여기서 바로 Dialog 콜
            ),
          ],
        ),
      ),
    );
  }

  Widget _sep() => Container(height: 1, color: _line);
}
