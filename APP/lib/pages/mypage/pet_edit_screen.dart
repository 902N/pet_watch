import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'package:APP/auth/env.dart';
import 'package:APP/auth/auth_api.dart' show AuthApi;
import 'package:APP/const/colors.dart';

import 'package:APP/login/data/dog_breeds_ko.dart';
import 'package:APP/login/widgets/fields_basic.dart';
import 'package:APP/login/widgets/white_decoration.dart'; // lilacSoftDecoration
import 'package:APP/widget/pet_id.dart';
import 'package:APP/api/s3_api.dart';
import 'package:APP/widget/app_font.dart';

class PetEditScreen extends StatefulWidget {
  final int? petId;
  const PetEditScreen({super.key, required this.petId});

  @override
  State<PetEditScreen> createState() => _PetEditScreenState();
}

class _PetEditScreenState extends State<PetEditScreen> {
  // ===== 색/스타일 (등록 화면과 동일 톤) =====
  static const _avatarBg  = Color(0xFFF2ECFF);
  static const _pawBrown  = Color(0xFFB89B84);
  static const _btnLilac  = Color(0xFFDCCBFF);
  static const _itemLilac = Color(0xFFF6F1FF);
  static const _itemBorder= Color(0xFFE6D9FF);

  BoxDecoration get _panelDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE9E3FF).withOpacity(0.15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ===== 컨트롤러/상태 =====
  final _formKey  = GlobalKey<FormState>();
  final nameCtrl  = TextEditingController();
  final breedCtrl = TextEditingController();
  final weightCtrl= TextEditingController();
  final imageCtrl = TextEditingController(); // 서버 URL or S3 업로드 URL
  DateTime? birth;

  String gender = 'M'; // M/F
  bool neutered = false;

  bool loading = false;
  bool saving  = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    weightCtrl.dispose();
    imageCtrl.dispose();
    super.dispose();
  }

  // ===== 서버 데이터 로드 =====
  Future<void> _loadDetail() async {
    if (widget.petId == null) return;
    setState(() => loading = true);
    try {
      final rsp = await AuthApi.client.get(
        '/pets/${widget.petId}',
        options: Options(validateStatus: (_) => true),
      );
      if (rsp.statusCode == 200) {
        final m = (rsp.data is Map<String, dynamic>)
            ? rsp.data as Map<String, dynamic>
            : <String, dynamic>{};
        final d = m['data'] as Map<String, dynamic>? ?? {};

        nameCtrl.text   = (d['name'] as String?) ?? '';
        breedCtrl.text  = (d['breed'] as String?) ?? '';
        weightCtrl.text = (d['weight']?.toString() ?? '');
        gender          = ((d['gender'] as String? ?? 'M').toUpperCase() == 'F') ? 'F' : 'M';
        neutered        = d['neutered'] as bool? ?? false;
        imageCtrl.text  = (d['profileImage'] as String?) ?? '';

        final birthStr = d['birthdate'] as String?;
        if (birthStr != null && birthStr.isNotEmpty) {
          final parsed = DateTime.tryParse(birthStr);
          if (parsed != null) birth = parsed;
        }
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ===== 저장(수정) =====
  Future<void> _save() async {
    if (widget.petId == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => saving = true);

    final wtText = weightCtrl.text.trim();
    final wtNum  = double.tryParse(wtText);

    final bodyMap = {
      'name'        : nameCtrl.text.trim(),
      'breed'       : breedCtrl.text.trim(),
      'birthdate'   : birth == null ? null : _fmtBirth(birth!),
      'gender'      : gender,
      'neutered'    : neutered,
      'weight'      : wtNum ?? wtText,
      'profileImage': imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
    };

    final rsp = await AuthApi.client.put(
      '/pets/${widget.petId}',
      data: bodyMap,
      options: Options(validateStatus: (_) => true),
    );

    setState(() => saving = false);
    if (!mounted) return;

    if (rsp.statusCode != null && rsp.statusCode! >= 200 && rsp.statusCode! < 300) {
      final baseUrl = dotenv.env['BASE_URL'] ?? Env.baseUrl;
      await context.read<PetIdStore>().refreshPets(baseUrl: baseUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정되었습니다.'), backgroundColor: AppColors.primaryAccent),
      );
      Navigator.pop(context, true);
    } else {
      final code = rsp.statusCode ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패 ($code)'), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _fmtBirth(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ===== 이미지 바텀시트 & S3 업로드 =====
  Future<void> _openImageSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadToS3(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadToS3(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('기본 이미지로 변경'),
              onTap: () {
                Navigator.pop(context);
                setState(() => imageCtrl.text = '');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadToS3(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 88);
      if (x == null) return;

      final file = File(x.path);
      final name = p.basename(file.path);
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
      final size = await file.length();

      final info = await S3Api.presign(fileName: name, mimeType: mime, fileSize: size);
      await S3Api.uploadFile(file, info, mimeType: mime);

      setState(() => imageCtrl.text = info.fileUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 완료'), backgroundColor: AppColors.primaryAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드 실패: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ===== 견종 선택 다이얼로그 =====
  Future<void> _pickBreed() async {
    String q = '';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final mq   = MediaQuery.of(ctx);
        final maxW = mq.size.width * 0.92;
        final maxH = mq.size.height * 0.72;
        return Dialog(
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: StatefulBuilder(
              builder: (ctx, setS) {
                final data = DogBreedsKo.all
                    .where((b) => b.toLowerCase().contains(q.toLowerCase()))
                    .toList();
                return SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text('견종 선택',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '견종 검색',
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1.2),
                            ),
                          ),
                          onChanged: (v) => setS(() => q = v),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: data.isEmpty
                              ? const Center(child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (_, i) {
                              final label = data[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor: const Color(0xFFEDE3FF),
                                    highlightColor: const Color(0xFFF2E9FF),
                                    onTap: () {
                                      setState(() => breedCtrl.text = label);
                                      Navigator.of(ctx).pop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _itemLilac,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _itemBorder),
                                      ),
                                      child: Text(label,
                                          style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ===== 성별 선택 다이얼로그(이모지만, 반씩 선택 카드) =====
  Future<void> _pickGender() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final colorMale   = const Color(0xFF3B82F6);
        final colorFemale = const Color(0xFFEF4444);

        Widget card(Color bg, String emoji, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: bg.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bg.withOpacity(0.35)),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
            ),
          ),
        );

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9E3FF).withOpacity(0.6), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppFont('성별 선택', size: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 24)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    card(colorMale, '♂️', () {
                      setState(() => gender = 'M');
                      Navigator.pop(ctx);
                    }),
                    const SizedBox(width: 12),
                    card(colorFemale, '♀️', () {
                      setState(() => gender = 'F');
                      Navigator.pop(ctx);
                    }),
                  ],
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ===== 생일 선택(등록 화면과 동일한 다이얼로그 + CupertinoPicker) =====
  Future<void> _pickBirth() async {
    final now = DateTime.now();
    const start = 1990;
    int y = (birth?.year ?? now.year).clamp(start, now.year);
    int m = birth?.month ?? now.month;
    int d = birth?.day ?? now.day;

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
                  border: Border.all(color: const Color(0xFFE9E3FF).withOpacity(0.6), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const AppFont('생년월일 선택', size: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 24)),
                    ]),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9E3FF), width: 1),
                      ),
                      child: Row(children: [
                        col(List.generate(now.year - start + 1, (i) => '${start + i}년'),
                            y - start, (i) => setS(() => y = start + i)),
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
                          setState(() => birth = DateTime(y, m, d));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _btnLilac,
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

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final genderColor = gender == 'M' ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    final genderEmoji = gender == 'M' ? '♂️' : '♀️';
    final birthText  = birth == null ? '선택하세요' : _fmtBirth(birth!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        centerTitle: true,
        title: const AppFont('펫 정보 수정', size: 23, fontWeight: FontWeight.w800, color: Colors.black87),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 아바타
                Center(
                  child: InkWell(
                    onTap: _openImageSheet,
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: _avatarBg,
                          backgroundImage: imageCtrl.text.isNotEmpty
                              ? NetworkImage(imageCtrl.text)
                              : null,
                          child: imageCtrl.text.isEmpty
                              ? const Icon(Icons.pets, size: 36, color: _pawBrown)
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xFFC4B5FD)),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 18, color: Color(0xFF8B5CF6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 기본 입력 (등록 화면과 동일)
                FieldsBasic(
                  nameCtrl: nameCtrl,
                  breedCtrl: breedCtrl,
                  weightCtrl: weightCtrl,
                  birthText: birthText,
                  onPickBirth: _pickBirth,
                  onPickBreed: _pickBreed,
                  decoration: lilacSoftDecoration,
                ),

                const SizedBox(height: 12),

                // 성별 & 중성화 (절반/절반)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _panelDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppFont('성별 & 중성화', size: 13, fontWeight: FontWeight.w800, color: Colors.black54),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // 성별 칩 (절반)
                          Expanded(
                            child: InkWell(
                              onTap: _pickGender,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _itemLilac,
                                  border: Border.all(color: _itemBorder),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(genderEmoji,
                                          style: TextStyle(fontSize: 20, color: genderColor)),
                                    ),
                                    const Positioned(
                                      right: 8,
                                      top: 6,
                                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 중성화 토글 (절반)
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _itemLilac,
                                border: Border.all(color: _itemBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ 이렇게
                                children: [
                                  const AppFont('중성화', size: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                                  Transform.scale(
                                    scale: 0.9,
                                    child: Switch(
                                      value: neutered,
                                      activeColor: const Color(0xFF8B5CF6),
                                      onChanged: (v) => setState(() => neutered = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btnLilac,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      saving ? '수정 중...' : '수정',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
