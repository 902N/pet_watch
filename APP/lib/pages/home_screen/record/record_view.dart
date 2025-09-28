// lib/pages/home_screen/record/record_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';
import 'package:APP/pages/home_screen/record/common/record_validation_mixin.dart';
import 'package:APP/widget/snackbar_helpers.dart';
import 'package:APP/pages/home_screen/record/widgets/category_selector.dart';
import 'package:APP/pages/home_screen/record/widgets/date_time_picker_row.dart';
import 'package:APP/pages/home_screen/record/widgets/media_picker_sheet.dart';
import 'package:APP/pages/home_screen/record/forms/walk_form.dart';
import 'package:APP/pages/home_screen/record/forms/meal_form.dart';
import 'package:APP/pages/home_screen/record/forms/health_form.dart';
import 'package:APP/pages/home_screen/record/forms/toilet_form.dart';
import 'package:APP/pages/home_screen/record/forms/memo_form.dart';
import 'package:APP/pages/home_screen/record/utils/toilet_condition_mapper.dart';
import 'package:APP/pages/home_screen/record/models/meal_record_models.dart';
import 'package:APP/pages/home_screen/record/services/meal_record_service.dart';
import 'package:APP/pages/home_screen/record/models/walk_record_models.dart';
import 'package:APP/pages/home_screen/record/services/walk_record_service.dart';
import 'package:APP/pages/home_screen/record/models/excretion_record_models.dart';
import 'package:APP/pages/home_screen/record/services/excretion_record_service.dart';
import 'package:APP/pages/home_screen/record/models/health_record_models.dart';
import 'package:APP/pages/home_screen/record/services/health_record_service.dart';
import 'package:APP/pages/home_screen/record/models/free_record_models.dart';
import 'package:APP/pages/home_screen/record/services/free_record_service.dart';
import 'package:APP/api/s3_api.dart';
import 'package:APP/widget/app_font.dart';

class RecordView extends StatefulWidget {
  final DateTime selectedDate;
  final Schedule? existingSchedule;
  final int? petId;
  final String? accessToken;

  const RecordView({
    super.key,
    required this.selectedDate,
    this.existingSchedule,
    this.petId,
    this.accessToken,
  });

  @override
  State<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> with RecordValidationMixin {
  String selectedCategory = 'walk';
  int _selectedHour = 0;
  int _selectedMinute = 0;
  late DateTime _selectedDate;

  final TextEditingController _mealDetailController = TextEditingController();
  final TextEditingController _memoContentController = TextEditingController();
  String? _memoImageUrl;

  int _walkDuration = 30;
  String _walkIntensity = '보통';
  int _mealAmount = 100;
  String _mealType = '사료';
  String _mealDetail = '건식';

  final TextEditingController _symptomDescriptionController = TextEditingController();
  final FocusNode _symptomFocusNode = FocusNode();
  final GlobalKey _symptomFieldKey = GlobalKey();
  bool _symptomError = false;

  String _toiletType = '대변';
  String _toiletCondition = '정상';

  String? _toiletImageUrl;
  String? _healthImageUrl;

  final ImagePicker _picker = ImagePicker();
  File? _pickedHealthImage;
  File? _pickedToiletImage;
  File? _pickedMemoImage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    if (widget.existingSchedule == null) {
      final now = DateTime.now();
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
    }
    _initializeFromExisting();
    _symptomDescriptionController.addListener(() {
      final hasText = _symptomDescriptionController.text.trim().isNotEmpty;
      if (_symptomError && hasText) {
        setState(() => _symptomError = false);
      } else {
        setState(() {}); // 버튼 enable 등 즉시 반영
      }
    });
  }

  void _initializeFromExisting() {
    final schedule = widget.existingSchedule;
    if (schedule == null) return;
    selectedCategory = schedule.category ?? 'walk';
    _selectedHour = schedule.startHour;
    _selectedMinute = schedule.startMinute;
    final data = schedule.categoryData ?? {};
    switch (selectedCategory) {
      case 'walk':
        _walkDuration = (data['walkDuration'] is int)
            ? data['walkDuration']
            : int.tryParse(data['walkDuration']?.toString() ?? '30') ?? 30;
        _walkIntensity = data['walkIntensity'] ?? '보통';
        break;
      case 'meal':
        _mealAmount = (data['mealAmount'] is int)
            ? data['mealAmount']
            : int.tryParse(data['mealAmount']?.toString() ?? '100') ?? 100;
        _mealType = data['mealType'] ?? '사료';
        final md = (data['mealDetail'] as String?) ?? '';
        _mealDetail = ['건식', '습식', '육포'].contains(md) ? md : '건식';
        _mealDetailController.text = md.isNotEmpty ? md : _mealDetail;
        break;
      case 'health':
        _symptomDescriptionController.text = data['symptomDescription'] ?? '';
        _healthImageUrl = data['healthImageUrl'];
        break;
      case 'toilet':
        _toiletType = data['toiletType'] ?? '대변';
        _toiletCondition = data['toiletCondition'] ?? _getDefaultConditionForType(_toiletType);
        _toiletImageUrl = data['toiletImageUrl'];
        break;
      case 'memo':
        _memoContentController.text = data['memoContent'] ?? schedule.content;
        _memoImageUrl = data['memoImageUrl'];
        break;
    }
  }

  @override
  void dispose() {
    _mealDetailController.dispose();
    _symptomDescriptionController.dispose();
    _symptomFocusNode.dispose();
    _memoContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = kCategoryColorMap[selectedCategory] ?? const Color(0xFFBDBDBD);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const AppFont('기록하기', size: 23, fontWeight: FontWeight.w800, color: Colors.black87),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            CategorySelector(
              selectedCategory: selectedCategory,
              onCategoryChanged: (c) {
                setState(() {
                  selectedCategory = c;
                  _resetFormDefaultsIfCreateMode();
                });
              },
            ),
            const SizedBox(height: 8),
            _SectionCard(
              title: '날짜 & 시간',
              borderColor: baseColor,
              child: DateTimePickerRow(
                selectedDate: _selectedDate,
                selectedHour: _selectedHour,
                selectedMinute: _selectedMinute,
                onSelectDate: _selectDate,
                onSelectTime: _selectTime,
                baseColor: baseColor,
              ),
            ),
            _SectionCard(
              title: '기록 입력',
              borderColor: baseColor,
              child: _buildCategoryForm(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: baseColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.existingSchedule != null ? '수정하기' : '저장하기',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultConditionForType(String type) {
    const conditionOptionsByType = {
      '대변': ['정상', '설사', '변비', '혈변', '점액변', '기생충변', '기타'],
      '소변': ['정상', '혈뇨', '탁한 소변', '진한 황색', '주황색/초록색', '아주 옅은 색', '기타'],
    };
    return conditionOptionsByType[type]?.first ?? '정상';
  }

  void _resetFormDefaultsIfCreateMode() {
    if (widget.existingSchedule != null) return;
    _mealDetailController.clear();
    _symptomDescriptionController.clear();
    _memoContentController.clear();
    _walkDuration = 30;
    _walkIntensity = '보통';
    _mealAmount = 100;
    _mealType = '사료';
    _mealDetail = '건식';
    _mealDetailController.text = _mealDetail;
    _toiletType = '대변';
    _toiletCondition = _getDefaultConditionForType(_toiletType);
    _toiletImageUrl = null;
    _healthImageUrl = null;
    _memoImageUrl = null;
    _pickedHealthImage = null;
    _pickedToiletImage = null;
    _pickedMemoImage = null;
  }

  void _selectDate() async {
    final now = DateTime.now();
    const start = 1990;

    int y = _selectedDate.year.clamp(start, now.year);
    int m = _selectedDate.month;
    int d = _selectedDate.day;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setS) {
            final days = DateTime(m == 12 ? y + 1 : y, m == 12 ? 1 : m + 1, 0).day;
            if (d > days) d = days;

            Widget col(List<String> items, int initial, ValueChanged<int> on) {
              return Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: initial),
                  onSelectedItemChanged: on,
                  children: items.map((e) => Center(child: Text(e))).toList(),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (kCategoryColorMap[selectedCategory] ?? AppColors.primaryAccent).withOpacity(0.3), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const AppFont('날짜 선택', size: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ]),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (kCategoryColorMap[selectedCategory] ?? const Color.fromRGBO(199, 179, 245, 1)).withOpacity(0.2), width: 1),
                      ),
                      child: Row(children: [
                        col(List.generate(now.year - start + 1, (i) => '${start + i}년'), y - start, (i) => setS(() => y = start + i)),
                        col(List.generate(12, (i) => '${i + 1}월'), m - 1, (i) => setS(() => m = i + 1)),
                        col(List.generate(days, (i) => '${i + 1}일'), d - 1, (i) => setS(() => d = i + 1)),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedDate = DateTime(y, m, d, _selectedHour, _selectedMinute));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kCategoryColorMap[selectedCategory] ?? AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const AppFont('확인', size: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectTime() async {
    int h = _selectedHour;
    int min = _selectedMinute;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setS) {
            Widget col(List<String> items, int initial, ValueChanged<int> on) {
              return Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: initial),
                  onSelectedItemChanged: on,
                  children: items.map((e) => Center(child: Text(e))).toList(),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (kCategoryColorMap[selectedCategory] ?? AppColors.primaryAccent).withOpacity(0.3), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const AppFont('시간 선택', size: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ]),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (kCategoryColorMap[selectedCategory] ?? AppColors.primaryAccent).withOpacity(0.2), width: 1),
                      ),
                      child: Row(children: [
                        col(List.generate(24, (i) => '${i.toString().padLeft(2, '0')}시'), h, (i) => setS(() => h = i)),
                        col(List.generate(60, (i) => '${i.toString().padLeft(2, '0')}분'), min, (i) => setS(() => min = i)),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedHour = h;
                            _selectedMinute = min;
                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour, _selectedMinute);
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kCategoryColorMap[selectedCategory] ?? AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const AppFont('확인', size: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryForm() {
    switch (selectedCategory) {
      case 'walk':
        return WalkForm(
          walkDuration: _walkDuration,
          onDurationChanged: (v) => setState(() => _walkDuration = v),
          selectedIntensity: _walkIntensity,
          onIntensityChanged: (v) => setState(() => _walkIntensity = v),
        );
      case 'meal':
        return MealForm(
          amount: _mealAmount,
          onAmountChanged: (v) => setState(() => _mealAmount = v),
          selectedType: _mealType,
          onTypeChanged: (v) => setState(() => _mealType = v),
          selectedDetail: _mealDetail,
          onDetailChanged: (v) => setState(() {
            _mealDetail = v;
            _mealDetailController.text = v;
          }),
          detailController: _mealDetailController,
        );
      case 'health':
        return HealthForm(
          symptomDescriptionController: _symptomDescriptionController,
          imageUrl: _healthImageUrl,
          localImageFile: _pickedHealthImage,
          onImageTap: _showImagePicker,
          symptomFocusNode: _symptomFocusNode,
          showSymptomError: _symptomError && _symptomDescriptionController.text.trim().isEmpty,
          symptomFieldKey: _symptomFieldKey,
        );
      case 'toilet':
        return ToiletForm(
          selectedType: _toiletType,
          onTypeChanged: (type) => setState(() {
            _toiletType = type;
            _toiletCondition = _getDefaultConditionForType(type);
          }),
          selectedCondition: _toiletCondition,
          onConditionChanged: (condition) => setState(() => _toiletCondition = condition),
          imageUrl: _toiletImageUrl,
          localImageFile: _pickedToiletImage,
          onImageTap: _showImagePicker,
        );
      case 'memo':
        return MemoForm(
          contentController: _memoContentController,
          imageUrl: _memoImageUrl,
          localImageFile: _pickedMemoImage,
          onImageTap: _showImagePicker,
        );
      default:
        return WalkForm(
          walkDuration: _walkDuration,
          onDurationChanged: (v) => setState(() => _walkDuration = v),
          selectedIntensity: _walkIntensity,
          onIntensityChanged: (v) => setState(() => _walkIntensity = v),
        );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MediaPickerSheet(
        onPickImage: _pickImageFromGallery,
        onTakePicture: _takePicture,
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final f = File(x.path);
    if (selectedCategory == 'health') {
      setState(() { _pickedHealthImage = f; _healthImageUrl = null; });
    } else if (selectedCategory == 'toilet') {
      setState(() { _pickedToiletImage = f; _toiletImageUrl = null; });
    } else if (selectedCategory == 'memo') {
      setState(() { _pickedMemoImage = f; _memoImageUrl = null; });
    }
  }

  Future<void> _takePicture() async {
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final f = File(x.path);
    if (selectedCategory == 'health') {
      setState(() { _pickedHealthImage = f; _healthImageUrl = null; });
    } else if (selectedCategory == 'toilet') {
      setState(() { _pickedToiletImage = f; _toiletImageUrl = null; });
    } else if (selectedCategory == 'memo') {
      setState(() { _pickedMemoImage = f; _memoImageUrl = null; });
    }
  }

  // 로컬시간(오프셋X) ISO (서버는 Z가 붙은 ISO로 응답하지만, 요청은 로컬 포맷으로 통일)
  String _isoLocalNoOffset(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final m = two(dt.month);
    final d = two(dt.day);
    final hh = two(dt.hour);
    final mm = two(dt.minute);
    final ss = two(dt.second);
    return '$y-$m-${d}T$hh:$mm:$ss';
  }

  String _guessMime(String path) {
    final n = path.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'application/octet-stream';
  }

  Future<void> _saveRecord() async {
    try {
      final canUseApi = (widget.petId != null && widget.accessToken != null);
      if (!canUseApi) {
        throw Exception('로그인(펫 선택) 후 기록할 수 있어요.');
      }

      Schedule? created;

      if (selectedCategory == 'meal') {
        created = await _saveMealRecordAndBuild();
      } else if (selectedCategory == 'walk') {
        created = await _saveWalkRecordAndBuild();
      } else if (selectedCategory == 'toilet') {
        created = await _saveExcretionRecordAndBuild();
      } else if (selectedCategory == 'health') {
        final empty = _symptomDescriptionController.text.trim().isEmpty;
        if (empty) {
          setState(() => _symptomError = true);
          _focusAndScrollToSymptom();
          return;
        } else {
          setState(() => _symptomError = false);
        }
        created = await _saveHealthRecordAndBuild();
      } else if (selectedCategory == 'memo') {
        created = await _saveFreeRecordAndBuild();
      }

      if (created == null) throw Exception('알 수 없는 카테고리');

      showSuccessSnack(context, widget.existingSchedule != null ? '기록이 수정되었습니다!' : '기록이 저장되었습니다!');
      Navigator.of(context).pop(created);
    } catch (e) {
      showErrorSnack(context, '기록 저장 중 오류가 발생했습니다: $e');
    }
  }

  void _focusAndScrollToSymptom() {
    _symptomFocusNode.requestFocus();
    final ctx = _symptomFieldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.2);
    }
  }

  int _tempId() => DateTime.now().microsecondsSinceEpoch;

  int? _extractCreatedId(dynamic res) {
    try {
      final dynamic data = (res as dynamic).data;
      if (data == null) return null;
      if (data is Map) {
        return (data['id'] ?? data['recordId']) as int?;
      }
      final dynamic id = (data as dynamic).id ?? (data as dynamic).recordId;
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<Schedule> _saveMealRecordAndBuild() async {
    final dtLocal = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour, _selectedMinute, 0);
    final req = MealRecordRequest(
      recordCategory: '식사',
      recordDateTime: _isoLocalNoOffset(dtLocal),
      type: _mealType,
      detail: _mealDetailController.text.isNotEmpty ? _mealDetailController.text : '기본',
      amount: _mealAmount,
    );
    final res = await MealRecordService.createMealRecord(
        petId: widget.petId!, accessToken: widget.accessToken!, request: req);
    if (!(res as dynamic).success) throw Exception((res as dynamic).message);

    final int? apiId = _extractCreatedId(res);
    final sid = apiId != null ? 'api_meal_$apiId' : 'temp_meal_${_tempId()}';
    return Schedule(
      id: sid,
      date: dtLocal,
      startHour: _selectedHour,
      startMinute: _selectedMinute,
      content: '밥 ${_mealAmount}g ($_mealType${_mealDetailController.text.isNotEmpty ? ' - ${_mealDetailController.text}' : ''})',
      category: 'meal',
      categoryData: {
        'mealAmount': _mealAmount,
        'mealType': _mealType,
        'mealDetail': _mealDetailController.text,
        if (apiId != null) 'apiRecordId': apiId else 'isServerPending': true,
      },
    );
  }

  Future<Schedule> _saveWalkRecordAndBuild() async {
    final dtLocal = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour, _selectedMinute);
    final request = WalkRecordRequest(
      recordCategory: '산책',
      recordDateTime: _isoLocalNoOffset(dtLocal),
      duration: _walkDuration,
      intensity: _walkIntensity,
    );
    final res = await WalkRecordService.createWalkRecord(
        petId: widget.petId!, accessToken: widget.accessToken!, request: request);
    if (!(res as dynamic).success) throw Exception((res as dynamic).message);

    final int? apiId = _extractCreatedId(res);
    final sid = apiId != null ? 'api_walk_$apiId' : 'temp_walk_${_tempId()}';
    return Schedule(
      id: sid,
      date: dtLocal,
      startHour: _selectedHour,
      startMinute: _selectedMinute,
      content: '산책 $_walkDuration분 ($_walkIntensity)',
      category: 'walk',
      categoryData: {
        'walkDuration': _walkDuration,
        'walkIntensity': _walkIntensity,
        if (apiId != null) 'apiRecordId': apiId else 'isServerPending': true,
      },
    );
  }

  Future<Schedule> _saveExcretionRecordAndBuild() async {
    String? finalUrl = _toiletImageUrl;
    if (_pickedToiletImage != null) {
      final f = _pickedToiletImage!;
      final name = f.path.split(Platform.pathSeparator).last;
      final mime = _guessMime(f.path);
      final size = await f.length();
      final presign = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
      await S3Api.uploadFile(f, presign, mimeType: mime);
      finalUrl = presign.fileUrl;
      setState(() {
        _toiletImageUrl = finalUrl;
        _pickedToiletImage = null;
      });
    }

    final dtLocal = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour, _selectedMinute);
    final req = ExcretionRecordRequest(
      recordCategory: '배변',
      recordDate: _isoLocalNoOffset(dtLocal), // ★ recordDate 사용
      type: _toiletType,
      condition: ToiletConditionMapper.toApiValue(_toiletCondition),
      imageUrl: finalUrl,
    );
    final res = await ExcretionRecordService.createExcretionRecord(
        petId: widget.petId!, accessToken: widget.accessToken!, request: req);
    if (!(res as dynamic).success) throw Exception((res as dynamic).message);

    final int? apiId = _extractCreatedId(res);
    final sid = apiId != null ? 'api_toilet_$apiId' : 'temp_toilet_${_tempId()}';
    return Schedule(
      id: sid,
      date: dtLocal,
      startHour: _selectedHour,
      startMinute: _selectedMinute,
      content: '배변 $_toiletType (${ToiletConditionMapper.toUiValue(_toiletCondition)})',
      category: 'toilet',
      categoryData: {
        'toiletType': _toiletType,
        'toiletCondition': _toiletCondition,
        'toiletImageUrl': finalUrl,
        if (apiId != null) 'apiRecordId': apiId else 'isServerPending': true,
      },
    );
  }

  Future<Schedule> _saveHealthRecordAndBuild() async {
    if (_symptomDescriptionController.text.trim().isEmpty) {
      throw Exception('증상 설명을 입력해주세요.');
    }

    String? finalUrl = _healthImageUrl;
    if (_pickedHealthImage != null) {
      final file = _pickedHealthImage!;
      final name = file.path.split(Platform.pathSeparator).last;
      final mime = _guessMime(file.path);
      final size = await file.length();
      final presign = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
      await S3Api.uploadFile(file, presign, mimeType: mime);
      finalUrl = presign.fileUrl;
      setState(() {
        _healthImageUrl = finalUrl;
        _pickedHealthImage = null;
      });
    }

    final dtLocal = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour, _selectedMinute);
    final req = HealthRecordRequest(
      recordCategory: '건강',
      recordDate: _isoLocalNoOffset(dtLocal), // ★ recordDate 사용
      symptomDescription: _symptomDescriptionController.text.trim(),
      imgUrl: finalUrl,
    );
    final res = await HealthRecordService.createHealthRecord(
        petId: widget.petId!, accessToken: widget.accessToken!, request: req);
    if (!(res as dynamic).success) throw Exception((res as dynamic).message);

    final int? apiId = _extractCreatedId(res);
    final sid = apiId != null ? 'api_health_$apiId' : 'temp_health_${_tempId()}';
    return Schedule(
      id: sid,
      date: dtLocal,
      startHour: _selectedHour,
      startMinute: _selectedMinute,
      content: '건강 - ${_symptomDescriptionController.text.length > 20 ? '${_symptomDescriptionController.text.substring(0, 20)}...' : _symptomDescriptionController.text}',
      category: 'health',
      categoryData: {
        'symptomDescription': _symptomDescriptionController.text,
        'healthImageUrl': finalUrl,
        if (apiId != null) 'apiRecordId': apiId else 'isServerPending': true,
      },
    );
  }

  Future<Schedule> _saveFreeRecordAndBuild() async {
    if (_memoContentController.text.trim().isEmpty) {
      throw Exception('내용을 입력해주세요.');
    }

    String? finalUrl = _memoImageUrl;
    if (_pickedMemoImage != null) {
      final f = _pickedMemoImage!;
      final name = f.path.split(Platform.pathSeparator).last;
      final mime = _guessMime(f.path);
      final size = await f.length();
      final presign = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
      await S3Api.uploadFile(f, presign, mimeType: mime);
      finalUrl = presign.fileUrl;
      setState(() {
        _memoImageUrl = finalUrl;
        _pickedMemoImage = null;
      });
    }

    final dtLocal = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour, _selectedMinute);
      final req = FreeRecordRequest(
        recordCategory: '자유',
        recordDateTime: _isoLocalNoOffset(dtLocal), // ★ 올바른 필드명
        content: _memoContentController.text.trim(),
        imgUrl: finalUrl,
      );
    final res = await FreeRecordService.createFreeRecord(
        petId: widget.petId!, accessToken: widget.accessToken!, request: req);
    if (!(res as dynamic).success) throw Exception((res as dynamic).message);

    final int? apiId = _extractCreatedId(res);
    final sid = apiId != null ? 'api_memo_$apiId' : 'temp_memo_${_tempId()}';
    return Schedule(
      id: sid,
      date: dtLocal,
      startHour: _selectedHour,
      startMinute: _selectedMinute,
      content: _memoContentController.text.length > 20
          ? '${_memoContentController.text.substring(0, 20)}...'
          : _memoContentController.text,
      category: 'memo',
      categoryData: {
        'memoContent': _memoContentController.text,
        'memoImageUrl': finalUrl,
        if (apiId != null) 'apiRecordId': apiId else 'isServerPending': true,
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;

  const _SectionCard({required this.title, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (borderColor ?? const Color(0xFFE9E3FF)).withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          AppFont(title, size: 13, fontWeight: FontWeight.w800, color: Colors.black54),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
