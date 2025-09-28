// lib/pages/mypage/widgets/user_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:APP/const/colors.dart';

class UserInfoDialog {
  static Future<void> show(
      BuildContext context, {
        required String name,
        required String email,
        required VoidCallback onLogout,
        required VoidCallback onWithdraw,
      }) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [Color(0xFFE9DFFF), Color(0xFFD7C9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person, color: Color(0xFF5B3FBF)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('사용자 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(Icons.close, color: AppColors.textPrimary),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이름', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF7F5FF), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF6B5BD5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: name));
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(content: Text('이름이 복사되었습니다.'), behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                              child: const Text('복사'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('이메일', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF7F5FF), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.alternate_email, size: 18, color: Color(0xFF6B5BD5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: email));
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(content: Text('이메일이 복사되었습니다.'), behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                              child: const Text('복사'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: AppColors.textPrimary.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            onLogout();
                          },
                          child: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: dialogContext,
                              builder: (ctx) => AlertDialog(
                                title: const Text('회원탈퇴'),
                                content: const Text('지금까지의 기록이 모두 삭제됩니다. 정말 탈퇴하시겠습니까?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('탈퇴', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true) {
                              Navigator.of(dialogContext).pop();
                              onWithdraw();
                            }
                          },
                          child: const Text('회원탈퇴', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEDE7F6),
                        foregroundColor: const Color(0xFF4C3DB5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
