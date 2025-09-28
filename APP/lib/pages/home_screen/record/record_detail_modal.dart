// lib/pages/home_screen/record/record_detail_modal.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:APP/const/colors.dart';
import 'package:APP/widget/snackbar_helpers.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

// forms
import 'package:APP/pages/home_screen/record/forms/walk_form.dart';
import 'package:APP/pages/home_screen/record/forms/meal_form.dart';
import 'package:APP/pages/home_screen/record/forms/health_form.dart';
import 'package:APP/pages/home_screen/record/forms/toilet_form.dart';
import 'package:APP/pages/home_screen/record/forms/memo_form.dart';
import 'package:APP/pages/home_screen/record/utils/toilet_condition_mapper.dart';

// services / models
import 'package:APP/pages/home_screen/record/services/walk_record_service.dart';
import 'package:APP/pages/home_screen/record/services/meal_record_service.dart';
import 'package:APP/pages/home_screen/record/services/health_record_service.dart';
import 'package:APP/pages/home_screen/record/services/excretion_record_service.dart';
import 'package:APP/pages/home_screen/record/services/free_record_service.dart';
import 'package:APP/pages/home_screen/record/models/walk_record_models.dart';
import 'package:APP/pages/home_screen/record/models/meal_record_models.dart';
import 'package:APP/pages/home_screen/record/models/health_record_models.dart';
import 'package:APP/pages/home_screen/record/models/excretion_record_models.dart';
import 'package:APP/pages/home_screen/record/models/free_record_models.dart';

import 'package:APP/pages/home_screen/record/widgets/media_picker_sheet.dart';
import 'package:APP/api/s3_api.dart';

Future<bool?> showRecordDetailModal({
  required BuildContext context,
  required int petId,
  required String accessToken,
  required String category,
  required int recordId,
  required Schedule schedule,
}) {
  final size = MediaQuery.of(context).size;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      // 더 크게: 화면 대부분 사용
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.06,
      ),
      child: RecordDetailModal(
        petId: petId,
        accessToken: accessToken,
        category: category,
        recordId: recordId,
        schedule: schedule,
      ),
    ),
  );
}

class RecordDetailModal extends StatefulWidget {
  final int petId;
  final String accessToken;
  final String category; // walk, meal, health, toilet, memo
  final int recordId;
  final Schedule schedule;

  const RecordDetailModal({
    super.key,
    required this.petId,
    required this.accessToken,
    required this.category,
    required this.recordId,
    required this.schedule,
  });

  @override
  State<RecordDetailModal> createState() => _RecordDetailModalState();
}

class _RecordDetailModalState extends State<RecordDetailModal> {
  bool _isLoading = false;
  bool _isSaving = false;

  Map<String, dynamic> _formData = {};
  DateTime? _recordDateTime;

  final _symptomController = TextEditingController();
  final _memoController = TextEditingController();
  final _mealDetailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _pickedMemoImage;
  File? _pickedHealthImage;
  File? _pickedToiletImage;

  String _bust(String url) => '$url?t=${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _fetchRecordData();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _memoController.dispose();
    _mealDetailController.dispose();
    super.dispose();
  }

  // ---------------- FETCH ----------------
  Future<void> _fetchRecordData() async {
    setState(() => _isLoading = true);
    try {
      switch (widget.category) {
        case 'walk':
          final r1 = await WalkRecordService.getWalkRecord(
              petId: widget.petId, accessToken: widget.accessToken, recordId: widget.recordId);
          final d1 = r1.data!;
          _formData = {'walkDuration': d1.duration, 'walkIntensity': d1.intensity};
          _recordDateTime = DateTime.tryParse(d1.recordDateTime);
          break;
        case 'meal':
          final r2 = await MealRecordService.getMealRecord(
              petId: widget.petId, accessToken: widget.accessToken, recordId: widget.recordId);
          final d2 = r2.data!;
          _formData = {'mealAmount': d2.amount, 'mealType': d2.type, 'mealDetail': d2.detail};
          _mealDetailController.text = d2.detail;
          _recordDateTime = DateTime.tryParse(d2.recordDateTime);
          break;
        case 'health':
          final r3 = await HealthRecordService.getHealthRecord(
              petId: widget.petId, accessToken: widget.accessToken, recordId: widget.recordId);
          final d3 = r3.data!;
          _formData = {'symptomDescription': d3.symptomDescription, 'healthImageUrl': d3.imgUrl};
          _symptomController.text = d3.symptomDescription;
          _recordDateTime = DateTime.tryParse(d3.recordDate); // 건강은 recordDate
          break;
        case 'toilet':
          final r4 = await ExcretionRecordService.getExcretionRecord(
              petId: widget.petId, accessToken: widget.accessToken, recordId: widget.recordId);
          final d4 = r4.data!;
          _formData = {
            'toiletType': d4.type,
            'toiletCondition': ToiletConditionMapper.toUiValue(d4.condition),
            'toiletImageUrl': d4.imageUrl,
          };
          _recordDateTime = DateTime.tryParse(d4.recordDate); // 배변은 recordDate
          break;
        case 'memo':
          final r5 = await FreeRecordService.getFreeRecord(
              petId: widget.petId, accessToken: widget.accessToken, recordId: widget.recordId);
          final d5 = r5.data!;
          _formData = {'memoContent': d5.content, 'memoImageUrl': d5.imgUrl};
          _memoController.text = d5.content ?? '';
          _recordDateTime = (d5.recordDateTime?.isNotEmpty ?? false)
              ? DateTime.tryParse(d5.recordDateTime!)
              : null; // 메모는 recordDateTime
          break;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- SAVE ----------------
  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    try {
      switch (widget.category) {
        case 'walk':
          {
            final req = WalkRecordRequest(
              recordCategory: '산책',
              recordDateTime: _fmt(_recordDateTime ?? widget.schedule.date),
              duration: _formData['walkDuration'] ?? 30,
              intensity: _formData['walkIntensity'] ?? '보통',
            );
            final r = await WalkRecordService.updateWalkRecord(
                petId: widget.petId, recordId: widget.recordId,
                accessToken: widget.accessToken, request: req);
            if (!r.success) throw Exception(r.message);
            break;
          }
        case 'meal':
          {
            final req = MealRecordRequest(
              recordCategory: '식사',
              recordDateTime: _fmt(_recordDateTime ?? widget.schedule.date),
              type: _formData['mealType'] ?? '사료',
              detail: _mealDetailController.text.trim().isNotEmpty
                  ? _mealDetailController.text.trim()
                  : (_formData['mealDetail'] ?? '건식'),
              amount: _formData['mealAmount'] ?? 100,
            );
            final r = await MealRecordService.updateMealRecord(
                petId: widget.petId, recordId: widget.recordId,
                accessToken: widget.accessToken, request: req);
            if (!r.success) throw Exception(r.message);
            break;
          }
        case 'health':
          {
            _formData['symptomDescription'] = _symptomController.text.trim();
            String? url = _formData['healthImageUrl'];
            if (_pickedHealthImage != null) {
              final f = _pickedHealthImage!;
              final name = f.path.split(Platform.pathSeparator).last;
              final mime = _guessMime(f.path);
              final size = await f.length();
              final p = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
              await S3Api.uploadFile(f, p, mimeType: mime);
              url = p.fileUrl;
              setState(() {
                _formData['healthImageUrl'] = _bust(url!);
                _pickedHealthImage = null;
              });
            }
            final req = HealthRecordRequest(
              recordCategory: '건강',
              recordDate: _fmt(_recordDateTime ?? widget.schedule.date),
              symptomDescription: _formData['symptomDescription'] ?? '',
              imgUrl: url,
            );
            final r = await HealthRecordService.updateHealthRecord(
                petId: widget.petId, recordId: widget.recordId,
                accessToken: widget.accessToken, request: req);
            if (!r.success) throw Exception(r.message);
            break;
          }
        case 'toilet':
          {
            String? url = _formData['toiletImageUrl'];
            if (_pickedToiletImage != null) {
              final f = _pickedToiletImage!;
              final name = f.path.split(Platform.pathSeparator).last;
              final mime = _guessMime(f.path);
              final size = await f.length();
              final p = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
              await S3Api.uploadFile(f, p, mimeType: mime);
              url = p.fileUrl;
              setState(() {
                _formData['toiletImageUrl'] = _bust(url!);
                _pickedToiletImage = null;
              });
            }
            final req = ExcretionRecordRequest(
              recordCategory: '배변',
              recordDate: _fmt(_recordDateTime ?? widget.schedule.date),
              type: _formData['toiletType'] ?? '대변',
              condition: ToiletConditionMapper.toApiValue(_formData['toiletCondition'] ?? '정상'),
              imageUrl: url,
            );
            final r = await ExcretionRecordService.updateExcretionRecord(
                petId: widget.petId, recordId: widget.recordId,
                accessToken: widget.accessToken, request: req);
            if (!r.success) throw Exception(r.message);
            break;
          }
        case 'memo':
          {
            _formData['memoContent'] = _memoController.text.trim();
            String? url = _formData['memoImageUrl'];
            if (_pickedMemoImage != null) {
              final f = _pickedMemoImage!;
              final name = f.path.split(Platform.pathSeparator).last;
              final mime = _guessMime(f.path);
              final size = await f.length();
              final p = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
              await S3Api.uploadFile(f, p, mimeType: mime);
              url = p.fileUrl;
              setState(() {
                _formData['memoImageUrl'] = _bust(url!);
                _pickedMemoImage = null;
              });
            }
            final req = FreeRecordRequest(
              recordCategory: '자유',
              recordDateTime: _fmt(_recordDateTime ?? widget.schedule.date),
              content: _formData['memoContent'] ?? '',
              imgUrl: url,
            );
            final r = await FreeRecordService.updateFreeRecord(
                petId: widget.petId, recordId: widget.recordId,
                accessToken: widget.accessToken, request: req);
            if (!r.success) throw Exception(r.message);
            break;
          }
      }
      showSuccessSnack(context, '기록이 성공적으로 수정되었습니다');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _errorSnack('기록 저장 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ---------------- DELETE ----------------
  Future<void> _deleteRecord() async {
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

    setState(() => _isSaving = true);
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
        case 'health':
          await HealthRecordService.deleteHealthRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
        case 'toilet':
          await ExcretionRecordService.deleteExcretionRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
        case 'memo':
          await FreeRecordService.deleteFreeRecord(
              petId: widget.petId, recordId: widget.recordId, accessToken: widget.accessToken);
          break;
      }
      showSuccessSnack(context, '기록이 성공적으로 삭제되었습니다');
      if (mounted) Navigator.of(context).pop('deleted');
    } catch (e) {
      _errorSnack('기록 삭제 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom; // 실제 키보드 높이

    // 핵심: 모달은 키보드 인셋을 제거해서 "크기가 줄지 않게" 유지
    return MediaQuery.removeViewInsets(
      removeBottom: true,
      context: context,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520, // 더 넓게
          ),
          child: FractionallySizedBox(
            heightFactor: 0.9, // 항상 큰 높이 유지
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _header(),
                  if (_isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                  // 스크롤 영역에만 키보드 높이만큼 패딩을 넣어 가려지지 않게
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + kb),
                        child: _formByCategory(),
                      ),
                    ),
                  _actionBar(), // 버튼은 고정, 항상 보임
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final title = _titleByCategory(widget.category);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          IconButton(onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close, size: 20)),
        ],
      ),
    );
  }

  Widget _formByCategory() {
    switch (widget.category) {
      case 'walk':
        return WalkForm(
          walkDuration: _formData['walkDuration'] ?? 30,
          onDurationChanged: (v) => _formData['walkDuration'] = v,
          selectedIntensity: _formData['walkIntensity'] ?? '보통',
          onIntensityChanged: (v) => _formData['walkIntensity'] = v,
        );
      case 'meal':
        return MealForm(
          amount: _formData['mealAmount'] ?? 100,
          onAmountChanged: (v) => _formData['mealAmount'] = v,
          selectedType: _formData['mealType'] ?? '사료',
          onTypeChanged: (v) {
            _formData['mealType'] = v;
            _formData['mealDetail'] = v;
          },
          selectedDetail: _formData['mealDetail'] ?? '건식',
          onDetailChanged: (v) {
            _formData['mealDetail'] = v;
            _mealDetailController.text = v;
          },
          detailController: _mealDetailController,
        );
      case 'health':
        return HealthForm(
          symptomDescriptionController: _symptomController,
          imageUrl: _formData['healthImageUrl'],
          localImageFile: _pickedHealthImage,
          onImageTap: _openHealthImageSheet,
        );
      case 'toilet':
        return ToiletForm(
          selectedType: _formData['toiletType'] ?? '대변',
          onTypeChanged: (v) => _formData['toiletType'] = v,
          selectedCondition: _formData['toiletCondition'] ?? '정상',
          onConditionChanged: (v) => _formData['toiletCondition'] = v,
          imageUrl: _formData['toiletImageUrl'],
          localImageFile: _pickedToiletImage,
          onImageTap: _openToiletImageSheet,
        );
      case 'memo':
        return MemoForm(
          contentController: _memoController,
          imageUrl: _formData['memoImageUrl'],
          localImageFile: _pickedMemoImage,
          onImageTap: _openMemoImageSheet,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionBar() {
    final baseColor = kCategoryColorMap[widget.category] ?? const Color(0xFF7C83A7);
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: baseColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('수정', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _deleteRecord,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- IMAGE PICK ----------------
  void _openMemoImageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MediaPickerSheet(
        onPickImage: _pickMemoFromGallery,
        onTakePicture: _takeMemoPicture,
      ),
    );
  }

  void _openHealthImageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MediaPickerSheet(
        onPickImage: _pickHealthFromGallery,
        onTakePicture: _takeHealthPicture,
      ),
    );
  }

  void _openToiletImageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MediaPickerSheet(
        onPickImage: _pickToiletFromGallery,
        onTakePicture: _takeToiletPicture,
      ),
    );
  }

  Future<void> _pickMemoFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedMemoImage = File(x.path));
  }

  Future<void> _takeMemoPicture() async {
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedMemoImage = File(x.path));
  }

  Future<void> _pickHealthFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedHealthImage = File(x.path));
  }

  Future<void> _takeHealthPicture() async {
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedHealthImage = File(x.path));
  }

  Future<void> _pickToiletFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedToiletImage = File(x.path));
  }

  Future<void> _takeToiletPicture() async {
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedToiletImage = File(x.path));
  }

  // ---------------- UTIL ----------------
  String _guessMime(String path) {
    final n = path.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic') || n.endsWith('.heif')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  void _errorSnack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 1),
    ));
  }

  String _titleByCategory(String c) {
    switch (c) {
      case 'walk': return '산책 기록 수정';
      case 'meal': return '식사 기록 수정';
      case 'toilet': return '배변 기록 수정';
      case 'health': return '건강 기록 수정';
      case 'memo': return '메모 수정';
      default: return '기록 수정';
    }
  }
}
