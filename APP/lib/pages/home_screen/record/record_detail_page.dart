// lib/pages/home_screen/record/record_detail_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';
import 'package:APP/pages/home_screen/record/services/walk_record_service.dart';
import 'package:APP/pages/home_screen/record/services/meal_record_service.dart';
import 'package:APP/pages/home_screen/record/services/excretion_record_service.dart';
import 'package:APP/pages/home_screen/record/services/health_record_service.dart';
import 'package:APP/pages/home_screen/record/services/free_record_service.dart';
import 'package:APP/pages/home_screen/record/models/walk_record_models.dart';
import 'package:APP/pages/home_screen/record/models/meal_record_models.dart';
import 'package:APP/pages/home_screen/record/models/excretion_record_models.dart';
import 'package:APP/pages/home_screen/record/models/health_record_models.dart';
import 'package:APP/pages/home_screen/record/models/free_record_models.dart';
import 'package:APP/pages/home_screen/record/forms/meal_form.dart';
import 'package:APP/pages/home_screen/record/forms/toilet_form.dart';
import 'package:APP/pages/home_screen/record/forms/health_form.dart';
import 'package:APP/pages/home_screen/record/forms/memo_form.dart';
import 'package:APP/pages/home_screen/record/utils/toilet_condition_mapper.dart';
import 'package:APP/pages/home_screen/record/widgets/media_picker_sheet.dart';
import 'package:APP/api/s3_api.dart';

class RecordDetailPage extends StatefulWidget {
  final int petId;
  final String accessToken;
  final String category;
  final int recordId;
  final Schedule schedule;

  const RecordDetailPage({
    super.key,
    required this.petId,
    required this.accessToken,
    required this.category,
    required this.recordId,
    required this.schedule,
  });

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  bool loading = false;

  int walkDuration = 30;
  String walkIntensity = '보통';

  int mealAmount = 100;
  String mealType = '사료';
  String mealDetail = '건식';

  String toiletType = '대변';
  String toiletCondition = '정상';
  String? toiletImg;
  File? _pickedToiletImage;

  String symptomDescription = '';
  String? healthImg;
  File? _pickedHealthImage;

  String memoContent = '';
  String? memoImg;
  File? _pickedMemoImage;

  final _symptomController = TextEditingController();
  final _memoController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  DateTime? _originalDateTime;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _memoController.dispose();
    super.dispose();
  }

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
    if (n.endsWith('.heic') || n.endsWith('.heif')) return 'image/heic';
    return 'application/octet-stream';
  }

  Future<String> _uploadToS3(File file) async {
    final name = file.path.split(Platform.pathSeparator).last;
    final mime = _guessMime(file.path);
    final size = await file.length();
    final presign = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
    await S3Api.uploadFile(file, presign, mimeType: mime);
    return presign.fileUrl;
  }

  Future<void> _fetch() async {
    setState(() => loading = true);
    try {
      switch (widget.category) {
        case 'walk':
          final res = await WalkRecordService.getWalkRecord(
            petId: widget.petId,
            accessToken: widget.accessToken,
            recordId: widget.recordId,
          );
          final d = res.data!;
          walkDuration = d.duration;
          walkIntensity = d.intensity;
          _originalDateTime = DateTime.tryParse(d.recordDateTime);
          break;
        case 'meal':
          final res = await MealRecordService.getMealRecord(
            petId: widget.petId,
            accessToken: widget.accessToken,
            recordId: widget.recordId,
          );
          final d = res.data!;
          mealAmount = d.amount;
          mealType = d.type;
          mealDetail = d.detail;
          _originalDateTime = DateTime.tryParse(d.recordDateTime);
          break;
        case 'toilet':
          final res = await ExcretionRecordService.getExcretionRecord(
            petId: widget.petId,
            accessToken: widget.accessToken,
            recordId: widget.recordId,
          );
          final d = res.data!;
          toiletType = d.type;
          toiletCondition = ToiletConditionMapper.toUiValue(d.condition);
          toiletImg = d.imageUrl;
          _originalDateTime = DateTime.tryParse(d.recordDateTime);
          break;
        case 'health':
          final res = await HealthRecordService.getHealthRecord(
            petId: widget.petId,
            accessToken: widget.accessToken,
            recordId: widget.recordId,
          );
          final d = res.data!;
          symptomDescription = d.symptomDescription;
          healthImg = d.imgUrl;
          _symptomController.text = symptomDescription;
          _originalDateTime = DateTime.tryParse(d.recordDateTime);
          break;
        case 'memo':
          final res = await FreeRecordService.getFreeRecord(
            petId: widget.petId,
            accessToken: widget.accessToken,
            recordId: widget.recordId,
          );
          final d = res.data!;
          memoContent = d.content ?? '';
          memoImg = d.imgUrl;
          _memoController.text = memoContent;
          _originalDateTime = DateTime.tryParse(d.recordDateTime);
          break;
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _update() async {
    setState(() => loading = true);
    try {
      final dt = _originalDateTime ?? widget.schedule.date;

      if (_pickedToiletImage != null) {
        toiletImg = await _uploadToS3(_pickedToiletImage!);
        _pickedToiletImage = null;
      }
      if (_pickedHealthImage != null) {
        healthImg = await _uploadToS3(_pickedHealthImage!);
        _pickedHealthImage = null;
      }
      if (_pickedMemoImage != null) {
        memoImg = await _uploadToS3(_pickedMemoImage!);
        _pickedMemoImage = null;
      }

      symptomDescription = _symptomController.text.trim();
      memoContent = _memoController.text.trim();

      switch (widget.category) {
        case 'walk':
          final reqWalk = WalkRecordRequest(
            recordCategory: '산책',
            recordDateTime: _isoLocalNoOffset(dt),
            duration: walkDuration,
            intensity: walkIntensity,
          );
          await WalkRecordService.updateWalkRecord(
            petId: widget.petId,
            recordId: widget.recordId,
            accessToken: widget.accessToken,
            request: reqWalk,
          );
          break;
        case 'meal':
          final reqMeal = MealRecordRequest(
            recordCategory: '식사',
            recordDateTime: _isoLocalNoOffset(dt),
            type: mealType,
            detail: mealDetail,
            amount: mealAmount,
          );
          await MealRecordService.updateMealRecord(
            petId: widget.petId,
            recordId: widget.recordId,
            accessToken: widget.accessToken,
            request: reqMeal,
          );
          break;
        case 'toilet':
          final reqToilet = ExcretionRecordRequest(
            recordCategory: '배변',
            recordDateTime: _isoLocalNoOffset(dt),
            type: toiletType,
            condition: ToiletConditionMapper.toApiValue(toiletCondition),
            imageUrl: toiletImg,
          );
          await ExcretionRecordService.updateExcretionRecord(
            petId: widget.petId,
            recordId: widget.recordId,
            accessToken: widget.accessToken,
            request: reqToilet,
          );
          break;
        case 'health':
          final reqHealth = HealthRecordRequest(
            recordCategory: '건강',
            recordDateTime: _isoLocalNoOffset(dt),
            symptomDescription: symptomDescription,
            imgUrl: healthImg,
          );
          await HealthRecordService.updateHealthRecord(
            petId: widget.petId,
            recordId: widget.recordId,
            accessToken: widget.accessToken,
            request: reqHealth,
          );
          break;
        case 'memo':
          final reqMemo = FreeRecordRequest(
            recordCategory: '자유',
            recordDateTime: _isoLocalNoOffset(dt),
            content: memoContent,
            imgUrl: memoImg,
          );
          await FreeRecordService.updateFreeRecord(
            petId: widget.petId,
            recordId: widget.recordId,
            accessToken: widget.accessToken,
            request: reqMemo,
          );
          break;
      }

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openImageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: MediaPickerSheet(
          onPickImage: _pickFromGallery,
          onTakePicture: _takePicture,
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    _setPickedFile(File(x.path));
  }

  Future<void> _takePicture() async {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    _setPickedFile(File(x.path));
  }

  void _setPickedFile(File f) {
    setState(() {
      if (widget.category == 'health') {
        _pickedHealthImage = f;
        healthImg = null;
      } else if (widget.category == 'toilet') {
        _pickedToiletImage = f;
        toiletImg = null;
      } else if (widget.category == 'memo') {
        _pickedMemoImage = f;
        memoImg = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560, minWidth: 320),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            _titleByCategory(widget.category),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: loading ? null : () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(child: _buildBody()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: loading ? null : _update,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('수정'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: loading ? null : _delete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('삭제'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.category) {
      case 'walk':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Text('산책 시간'), const Spacer(), Text('$walkDuration 분')]),
            Slider(
              value: walkDuration.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              label: '$walkDuration',
              onChanged: (v) => setState(() => walkDuration = v.round()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: walkIntensity,
              items: const ['가벼움', '보통', '격렬함']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => walkIntensity = v ?? '보통'),
              decoration: const InputDecoration(labelText: '강도'),
            ),
          ],
        );
      case 'meal':
        return MealForm(
          amount: mealAmount,
          onAmountChanged: (amount) => setState(() => mealAmount = amount),
          selectedType: mealType,
          onTypeChanged: (type) {
            setState(() {
              mealType = type;
              final detailOptions =
                  MealForm.detailOptionsByType[type] ?? MealForm.detailOptionsByType['사료']!;
              mealDetail = detailOptions.first;
            });
          },
          selectedDetail: mealDetail,
          onDetailChanged: (detail) => setState(() => mealDetail = detail),
        );
      case 'toilet':
        return ToiletForm(
          selectedType: toiletType,
          onTypeChanged: (type) {
            setState(() {
              toiletType = type;
              final conditionOptions =
                  ToiletForm.conditionOptionsByType[type] ?? ToiletForm.conditionOptionsByType['대변']!;
              toiletCondition = conditionOptions.first;
            });
          },
          selectedCondition: toiletCondition,
          onConditionChanged: (condition) => setState(() => toiletCondition = condition),
          imageUrl: toiletImg,
          localImageFile: _pickedToiletImage,
          onImageTap: _openImageSheet,
        );
      case 'health':
        return HealthForm(
          symptomDescriptionController: _symptomController,
          imageUrl: healthImg,
          localImageFile: _pickedHealthImage,
          onImageTap: _openImageSheet,
        );
      case 'memo':
        return MemoForm(
          contentController: _memoController,
          imageUrl: memoImg,
          localImageFile: _pickedMemoImage,
          onImageTap: _openImageSheet,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 기록을 삭제합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => loading = true);
    try {
      switch (widget.category) {
        case 'walk':
          await WalkRecordService.deleteWalkRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
        case 'meal':
          await MealRecordService.deleteMealRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
        case 'toilet':
          await ExcretionRecordService.deleteExcretionRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
        case 'health':
          await HealthRecordService.deleteHealthRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
        case 'memo':
          await FreeRecordService.deleteFreeRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _titleByCategory(String c) {
    switch (c) {
      case 'walk':
        return '산책 기록 수정';
      case 'meal':
        return '식사 기록 수정';
      case 'toilet':
        return '배변 기록 수정';
      case 'health':
        return '건강 기록 수정';
      case 'memo':
        return '메모 수정';
      default:
        return '기록 수정';
    }
  }
}
