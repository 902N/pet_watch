import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:APP/widget/app_font.dart';
import 'package:APP/widget/pet_id.dart';
import 'package:APP/pages/mypage/widgets/pet_profile_card.dart';
import 'package:APP/pages/mypage/my_page_vm.dart';
import 'package:APP/guide/guideline_page.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  static void fetch(GlobalKey key) {
    final st = key.currentState;
    if (st is _MyPageScreenState) st._fetchUserInfo();
  }

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final ScrollController _scroll = ScrollController();

  Future<void> _fetchUserInfo() async {
    final vm = context.read<MyPageVM>();
    await vm.fetchUserInfo(context);
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 60));
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const f = 0.98;
    final petStore = context.watch<PetIdStore>();

    return ChangeNotifierProvider<MyPageVM>(
      create: (_) => MyPageVM(context.read<PetIdStore>())..start(),
      builder: (ctx, _) {
        final vm = ctx.watch<MyPageVM>();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            leadingWidth: MediaQuery.of(context).size.width * 0.6,
            leading: const Padding(
              padding: EdgeInsets.only(left: 25),
              child: Row(children: [AppFont('펫정보', size: 20, fontWeight: FontWeight.bold)]),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _fetchUserInfo,
            color: const Color(0xFF8B5CF6),
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                PetProfileCard(
                  key: ValueKey(petStore.petId),
                  profile: vm.profile,
                  onEdit: () => vm.openEdit(context),
                  loading: vm.loadingPet,
                ),
                const SizedBox(height: 4),
                Container(
                  key: const ValueKey('settings-bg-f7f2fa'),
                  margin: EdgeInsets.all(12 * f),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF7F2FA), Color(0xFFF7F2FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    boxShadow: [
                      BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppFont('설정', size: 16, fontWeight: FontWeight.w700),
                          const SizedBox(height: 10),
                          _SettingItem(
                            child: Row(
                              children: [
                                const AppFont('푸시 알림 수신', size: 15, fontWeight: FontWeight.w700),
                                const Spacer(),
                                Transform.scale(
                                  scale: 0.95,
                                  child: Switch(
                                    value: vm.agreeNotification,
                                    onChanged: vm.toggleNotification,
                                    activeColor: Colors.white,
                                    activeTrackColor: const Color(0xFF3B82F6),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFCBD5E1),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SettingItem(
                            onTap: () => vm.tapFetchUser(context),
                            child: const Row(
                              children: [
                                AppFont('계정 확인', size: 15, fontWeight: FontWeight.w700),
                                Spacer(),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SettingItem(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const GuidelinePage()),
                            ),
                            child: const Row(
                              children: [
                                _CircledIcon(),
                                SizedBox(width: 8),
                                AppFont('FAQ', size: 15, fontWeight: FontWeight.w700),
                                Spacer(),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _SettingItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _SettingItem({required this.child, this.onTap});

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final w = InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        height: _height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: w,
    );
  }
}

class _CircledIcon extends StatelessWidget {
  const _CircledIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F2FA),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: const Center(
        child: Icon(Icons.help_outline, size: 16, color: Colors.white),
      ),
    );
  }
}
