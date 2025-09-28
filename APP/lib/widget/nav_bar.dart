// widget/nav_bar.dart
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onDashboardTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onDashboardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 0, thickness: 1, color: Color(0x1F000000)),
        Material(
          surfaceTintColor: Colors.transparent,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            currentIndex: currentIndex,
            // ★ 로직 그대로 유지
            onTap: (i) {
              if (i == 1) onDashboardTap?.call();
              onTap(i);
            },

            // 라벨 표시는 기존 로직에 영향 없으니 그대로 두거나 필요하면 숨겨도 됩니다.
            // showSelectedLabels: false,
            // showUnselectedLabels: false,

            items: [
              BottomNavigationBarItem(
                icon: Image.asset('asset/icon/home.png', width: 35, height: 35),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('asset/icon/home.png', width: 35, height: 35),
                ),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Image.asset('asset/icon/dashboard.png', width: 35, height: 35),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('asset/icon/dashboard.png', width: 35, height: 35),
                ),
                label: '대시보드',
              ),
              BottomNavigationBarItem(
                icon: Image.asset('asset/icon/finance.png', width: 35, height: 35),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('asset/icon/finance.png', width: 35, height: 35),
                ),
                label: '금융상품',
              ),
              BottomNavigationBarItem(
                icon: Image.asset('asset/icon/mypage.png', width: 35, height: 35),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('asset/icon/mypage.png', width: 35, height: 35),
                ),
                label: '펫정보',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
