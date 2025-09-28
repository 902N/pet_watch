import 'package:flutter/material.dart';
import 'package:APP/widget/app_font.dart';
import 'savings/savings_view.dart';
import 'insurance/insurance_view.dart';
import 'ai/ai_view.dart';

class RecommendView extends StatefulWidget {
  const RecommendView({super.key});
  @override
  State<RecommendView> createState() => _RecommendViewState();
}

class _RecommendViewState extends State<RecommendView> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leadingWidth: MediaQuery.of(context).size.width * 0.6,
          leading: const Padding(
            padding: EdgeInsets.only(left: 25),
            child: Row(
              children: [AppFont('금융상품', size: 20, fontWeight: FontWeight.bold)],
            ),
          ),
          bottom: const TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.symmetric(horizontal: 24),
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: '보험'),
              Tab(text: '예적금'),
            ],
          ),
        ),
        floatingActionButton: const _AiFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: const SafeArea(
          top: false,
          child: ColoredBox(
            color: Colors.white,
            child: TabBarView(
              physics: BouncingScrollPhysics(),
              children: [InsuranceView(), SavingsView()],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiFab extends StatelessWidget {
  const _AiFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton.extended(
        heroTag: 'ai-recommend',
        backgroundColor: const Color(0xFFF2F4F7),
        foregroundColor: Colors.black,
        elevation: 2,
        shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE5E7EB))),
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) {
              final maxW = MediaQuery.of(ctx).size.width;
              final dialogWidth = maxW > 600 ? 560.0 : (maxW - 32); // 반응형 너비
              return Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: dialogWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5D4FF)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10)),
                      ],
                    ),
                    child: const AiRecommendSheet(), // 다이얼로그 콘텐츠
                  ),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI 추천'),
      ),
    );
  }
}
