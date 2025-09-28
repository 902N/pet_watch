// lib/pages/home_screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:APP/pages/home_screen/widgets/calendar_section.dart';
import 'package:APP/pages/home_screen/widgets/schedule_list_section.dart';
import 'package:APP/pages/home_screen/record/record_view.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';
import 'package:APP/pages/home_screen/controllers/home_screen_controller.dart';
import 'package:APP/widget/pet_id.dart';
import 'package:APP/login/dog_register_screen.dart';
import 'package:APP/pages/home_screen/record/record_detail_modal.dart';
import 'package:APP/pages/home_screen/widgets/notification_modal.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool _menuOpen = false;
  late final HomeScreenController _controller;
  int? _lastPetId;

  DateTime get selectedDate => _controller.selectedDate;
  List<Schedule> get filteredSchedules => _controller.filteredSchedules;
  int get selectedDateCount => _controller.selectedDateCount;
  Map<DateTime, List<Schedule>> get schedulesByDate =>
      _controller.schedulesByDate;
  bool get _isLoadingDayRecords => _controller.isLoadingDayRecords;

  @override
  void initState() {
    super.initState();
    _controller = HomeScreenController();
    _controller.addListener(_onControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      await context
          .read<PetIdStore>()
          .initFromUserMeAndPets(baseUrl: baseUrl);
      if (!mounted) return;

      final petId = _getSafePetId();
      if (petId == null) return;

      final token = await _getSafeAccessToken();
      if (token == null) return;

      await _controller.initialize(petId: petId, accessToken: token);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }

    final petStore = context.watch<PetIdStore>();
    if (petStore.petId != _lastPetId) {
      _lastPetId = petStore.petId;
      _handlePetChange();
    }
  }

  Future<void> _handlePetChange() async {
    if (!mounted) return;

    final petId = _getSafePetId();
    if (petId == null) return;

    final token = await _getSafeAccessToken();
    if (token == null) return;

    _controller.invalidateViewCaches();
    await _controller.refreshData(petId: petId, accessToken: token);
  }

  Future<void> _retryPetSwitch(int petId) async {
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      await context
          .read<PetIdStore>()
          .switchActive(baseUrl: baseUrl, targetPetId: petId);

      if (!mounted) return;
      setState(() => _menuOpen = false);

      final token = await _getSafeAccessToken();
      if (token == null) return;

      await _controller.switchPet(petId: petId, accessToken: token);

      if (mounted) {
        final petStore = context.read<PetIdStore>();
        final p = petStore.pets.firstWhere(
                (e) => e.id == petId,
            orElse: () => petStore.pets.first);
        _showSuccessSnack('${p.name}로 전환되었습니다.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('펫 전환 재시도 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _forceRecacheAndReload();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<String?> _getAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('access_token') ?? sp.getString('accessToken');
  }

  int? _getSafePetId() {
    if (!mounted) return null;
    final petId = context.read<PetIdStore>().petId;
    if (petId == null) {
      _showErrorDialog('펫 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
    }
    return petId;
  }

  Future<String?> _getSafeAccessToken() async {
    if (!mounted) return null;
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      _showErrorDialog('인증 토큰을 찾을 수 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인')),
        ],
      ),
    );
  }

  void _showStyledSnack(String message,
      {Color backgroundColor = Colors.green, int milliseconds = 1000}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(milliseconds: milliseconds),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    _showStyledSnack(message,
        backgroundColor: Colors.green, milliseconds: 1000);
  }

  @override
  Widget build(BuildContext context) {
    final petStore = context.watch<PetIdStore>();
    final petName = petStore.petName ?? '-';
    final petImg = petStore.petImage;
    final pets = petStore.pets;
    final currentId = petStore.petId;

    return Scaffold(
      resizeToAvoidBottomInset:
      false, // ✅ 키보드가 올라와도 HomeScreen 레이아웃을 리사이즈하지 않음(오버플로우 원천 차단)
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _menuOpen = !_menuOpen),
                        borderRadius: BorderRadius.circular(28),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE5E7EB),
                              backgroundImage: petImg != null && petImg.isNotEmpty
                                  ? NetworkImage(petImg)
                                  : null,
                              child: (petImg == null || petImg.isEmpty)
                                  ? const Icon(Icons.pets)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: 220),
                              child: Text(
                                petName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _menuOpen ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  size: 22),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _openRecordPage,
                        icon: Image.asset('asset/icon/record.png',
                            width: 28, height: 28),
                        tooltip: '기록하기',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: _openNotificationModal,
                        icon: Image.asset('asset/icon/notification.png',
                            width: 28, height: 28),
                        tooltip: '알림',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
                CalendarSection(
                  key: ValueKey(
                      'calendar_${currentId}_${DateTime.now().millisecondsSinceEpoch}'),
                  selectedDate: selectedDate,
                  focusedDay: selectedDate,
                  onDaySelected: (d, f) async {
                    setState(() => _menuOpen = false);
                    if (!mounted) return;

                    final petId = _getSafePetId();
                    if (petId == null) return;

                    final token = await _getSafeAccessToken();
                    if (token == null) return;

                    await _controller.changeSelectedDate(d,
                        petId: petId, accessToken: token);

                    if (mounted) {
                      final scrollController =
                      PrimaryScrollController.of(context);
                      if (scrollController.hasClients) {
                        scrollController.animateTo(0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut);
                      }
                    }
                  },
                  schedulesByDate: schedulesByDate,
                  selectedDateCount: selectedDateCount,
                ),
                if (_controller.isSwitchingPet)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('펫 정보를 불러오는 중...'),
                        ],
                      ),
                    ),
                  )
                else if (_isLoadingDayRecords)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else
                  ScheduleListSection(
                    schedules: filteredSchedules,
                    onTap: _openRecordDetail,
                  ),
              ],
            ),
          ),
          if (_menuOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _menuOpen = false),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: 0.06,
                  child: const ColoredBox(color: Colors.black),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding:
                  const EdgeInsets.only(top: 64, left: 16, right: 16),
                  child: _PetOverlayMenu(
                    pets: pets,
                    currentId: currentId,
                    onSelected: (id) async {
                      try {
                        final baseUrl = dotenv.env['BASE_URL'] ?? '';
                        await context
                            .read<PetIdStore>()
                            .switchActive(baseUrl: baseUrl, targetPetId: id);

                        if (!mounted) return;
                        setState(() => _menuOpen = false);

                        final token = await _getSafeAccessToken();
                        if (token == null) return;

                        await _controller.switchPet(
                            petId: id, accessToken: token);

                        if (mounted) {
                          final p = pets.firstWhere((e) => e.id == id,
                              orElse: () => pets.first);
                          _showSuccessSnack('${p.name}로 전환되었습니다.');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text('펫 전환 중 오류가 발생했습니다: $e'),
                              action: SnackBarAction(
                                label: '재시도',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _retryPetSwitch(id);
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                    onAdd: (pets.length < 5)
                        ? () async {
                      final baseUrl =
                          dotenv.env['BASE_URL'] ?? '';
                      if (!mounted) return;

                      final added = await Navigator.of(context)
                          .push<bool>(MaterialPageRoute(
                          builder: (_) =>
                          const DogRegisterScreen(
                              popOnSuccess: true)));

                      if (mounted) {
                        await context
                            .read<PetIdStore>()
                            .initFromUserMeAndPets(
                            baseUrl: baseUrl);
                      }

                      if (!mounted) return;
                      setState(() => _menuOpen = false);

                      final petId = _getSafePetId();
                      if (petId == null) return;

                      final token =
                      await _getSafeAccessToken();
                      if (token == null) return;

                      await _controller.refreshData(
                          petId: petId, accessToken: token);

                      if (mounted && added == true) {
                        _showSuccessSnack('반려동물이 추가되었습니다.');
                      }
                    }
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openNotificationModal() async {
    if (!mounted) return;

    final petId = _getSafePetId();
    if (petId == null) return;

    final token = await _getSafeAccessToken();
    if (token == null) return;

    final baseUrl = dotenv.env['BASE_URL'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return NotificationModal(
          petId: petId,
          accessToken: token,
          baseUrl: baseUrl,
        );
      },
    );
  }

  void _openRecordPage() async {
    if (!mounted) return;

    final petId = _getSafePetId();
    if (petId == null) return;

    final token = await _getSafeAccessToken();
    if (token == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordView(
            selectedDate: selectedDate,
            petId: petId,
            accessToken: token),
      ),
    );

    if (!mounted) return;

    DateTime target = selectedDate;
    if (result is Schedule) {
      _controller.addSchedule(result);
      target = result.date;
    } else if (result is DateTime) {
      target = result;
    }

    _controller.clearDayCache(petId, target);
    await _controller.changeSelectedDate(target,
        petId: petId, accessToken: token);
  }

  void _openRecordDetail(Schedule s) async {
    if (!mounted) return;

    final petId = _getSafePetId();
    if (petId == null) return;

    final token = await _getSafeAccessToken();
    if (token == null) return;

    final apiId = _extractApiId(s);
    if (apiId == null) return;

    dynamic result;
    if (mounted) {
      result = await showRecordDetailModal(
        context: context,
        petId: petId,
        accessToken: token,
        category: s.category ?? '',
        recordId: apiId,
        schedule: s,
      );
    }

    if (!mounted) return;

    if (result == true || result == 'deleted') {
      _controller.clearDayCache(petId, selectedDate);
      final token2 = await _getSafeAccessToken();
      if (token2 == null) return;
      await _controller.changeSelectedDate(selectedDate,
          petId: petId, accessToken: token2);
      await _controller.refreshMonthRecordsForDate(
          petId: petId, accessToken: token2, date: selectedDate);
    }
  }

  int? _extractApiId(Schedule s) => _controller.extractApiId(s);

  Future<void> _forceRecacheAndReload() async {
    final petId = context.read<PetIdStore>().petId;
    final token = await _getSafeAccessToken();
    if (token == null) return;
    await _controller.refreshData(petId: petId, accessToken: token);
  }
}

class _PetOverlayMenu extends StatelessWidget {
  final List<PetSummary> pets;
  final int? currentId;
  final ValueChanged<int> onSelected;
  final VoidCallback? onAdd;

  const _PetOverlayMenu({
    required this.pets,
    required this.currentId,
    required this.onSelected,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280, minWidth: 220),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in pets)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelected(p.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE5E7EB),
                            backgroundImage: p.profileImage.isNotEmpty
                                ? NetworkImage(p.profileImage)
                                : null,
                            child: p.profileImage.isEmpty
                                ? const Icon(Icons.pets, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (p.id == currentId)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                        ],
                      ),
                    ),
                  ),
                if (onAdd != null) ...[
                  const Divider(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onAdd,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFFE5E7EB),
                              child: Icon(Icons.add, size: 18)),
                          SizedBox(width: 10),
                          Text('반려동물 추가',
                              style:
                              TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
