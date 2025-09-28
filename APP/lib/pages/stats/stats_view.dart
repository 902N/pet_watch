import 'package:flutter/material.dart';
import 'package:APP/widget/app_font.dart';
import 'monthly/monthly_view.dart';
import 'weekly/weekly_view.dart';

class StatsView extends StatefulWidget {
    const StatsView({super.key});
    @override
    State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
    @override
    Widget build(BuildContext context) {
        return DefaultTabController(
            length: 2,
            child: Scaffold(
                backgroundColor: Colors.white, // ← 화면 배경 흰색
                appBar: AppBar(
                    backgroundColor: Colors.white,        // ← 앱바 흰색
                    elevation: 0,
                    scrolledUnderElevation: 0,            // 스크롤 틴트 방지
                    surfaceTintColor: Colors.transparent, // M3 틴트 제거
                    shadowColor: Colors.transparent,
                    leadingWidth: MediaQuery.of(context).size.width * 0.6,
                    leading: const Padding(
                        padding: EdgeInsets.only(left: 25),
                        child: Row(
                            children: [AppFont('대시보드', size: 20, fontWeight: FontWeight.bold)],
                        ),
                    ),
                    bottom: TabBar(
                        isScrollable: false,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                        // 탭 글자 항상 검정
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black,
                        // 필요하면 인디케이터 색 지정
                        // indicatorColor: AppColors.primaryAccent,
                        tabs: const [
                            Tab(text: '월간'),
                            Tab(text: '주간'),
                        ],
                    ),
                ),
                body: const SafeArea(
                    top: false,
                    child: ColoredBox( // ← TabBarView 영역도 흰색 보장
                        color: Colors.white,
                        child: TabBarView(
                            physics: BouncingScrollPhysics(),
                            children: [
                                MonthlyView(),
                                WeeklyView(),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
