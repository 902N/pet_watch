import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../models/pet_profile.dart';
import 'package:APP/auth/env.dart';
import 'package:APP/auth/auth_api.dart' show AuthApi;
import 'package:APP/widget/pet_id.dart';
import 'package:APP/pages/main_screen/main_screen.dart';
import 'package:APP/widget/app_font.dart';

enum PetProfileCardStyle { gradientBorder, neumorphic }

class PetProfileCard extends StatelessWidget {
  final PetProfile profile;
  final VoidCallback? onEdit;
  final bool loading;
  final PetProfileCardStyle style;

  const PetProfileCard({
    super.key,
    required this.profile,
    this.onEdit,
    this.loading = false,
    this.style = PetProfileCardStyle.gradientBorder,
  });

  // ▶ 요청 색상들
  static const _lav = Color(0xFFF7F2FA); // 라벤더 배경 (#F7F2FA)
  static const _deep = Color(0xFF5C3CF0); // 포인트 보라

  @override
  Widget build(BuildContext context) {
    const f = 0.98;
    final name = profile.name ?? '-';
    final breed = profile.breed ?? '-';
    final birth = (profile.birthdate?.trim().isNotEmpty ?? false) ? profile.birthdate! : '-';
    final gender = _genderEmoji(profile.gender);
    final neuter = _mapNeutered(profile.neutered);
    final img = profile.profileImage;

    final BoxDecoration cardDecoration = (style == PetProfileCardStyle.neumorphic)
        ? BoxDecoration(
      color: const Color(0xFFEDE7F6),
      borderRadius: BorderRadius.circular(22 * f),
      boxShadow: const [
        BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 10)),
        BoxShadow(color: Colors.white, blurRadius: 14, offset: Offset(-6, -6)),
      ],
    )
        : const BoxDecoration(
      // 카드 배경: 라벤더 단색 그라데(양 끝 동일)
      gradient: LinearGradient(
        colors: [_lav, _lav],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.all(Radius.circular(18)),
    );

    return Container(
      margin: EdgeInsets.all(12 * f),
      padding: EdgeInsets.fromLTRB(16 * f, 14 * f, 16 * f, 12 * f),
      decoration: cardDecoration,
      child: loading
          ? SizedBox(
        height: 160 * f,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      )
          : Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                _roundIconButton(
                  asset: 'asset/icon/record.png',
                  tooltip: '수정하기',
                  onTap: onEdit,
                  size: 20 * f,
                  pad: 6 * f,
                ),
                SizedBox(width: 6 * f),
                _roundIconButton(
                  asset: 'asset/icon/remove.png',
                  tooltip: '삭제하기',
                  onTap: () => _deletePet(context, profile.id ?? 0),
                  size: 20 * f,
                  pad: 6 * f,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 2 * f),

              // 제목만 왼쪽 정렬
              const Align(
                alignment: Alignment.centerLeft,
                child: AppFont(
                  '펫 카드',
                  size: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B0B0B),
                ),
              ),

              SizedBox(height: 6 * f),

              // 아바타: 테두리 그라데를 라벤더로
              Container(
                padding: EdgeInsets.all(3 * f),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (style == PetProfileCardStyle.gradientBorder)
                      ? const LinearGradient(
                    colors: [Colors.white, _lav],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  boxShadow: (style == PetProfileCardStyle.neumorphic)
                      ? const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
                    BoxShadow(color: Colors.white, blurRadius: 8, offset: Offset(-4, -4)),
                  ]
                      : const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6))
                  ],
                ),
                child: CircleAvatar(
                  radius: 50 * f,
                  backgroundColor: Colors.white,
                  backgroundImage: (img != null && img.isNotEmpty) ? NetworkImage(img) : null,
                  child: (img == null || img.isEmpty)
                      ? const Icon(Icons.pets, size: 40, color: _deep)
                      : null,
                ),
              ),

              SizedBox(height: 10 * f),
              const AppFont('', size: 0),

              AppFont(
                name,
                size: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B0B0B),
              ),

              SizedBox(height: 8 * f),

              // 정보 행들
              _infoRow('품종', breed, f: f, style: style),
              _infoRow('생년월일', birth, f: f, style: style),
              _infoRow('성별', gender, f: f, style: style),
              _infoRow('중성화', neuter, f: f, style: style),
              _infoRow('몸무게', _fmtWeight(profile.weight), f: f, style: style),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtWeight(num? w) {
    if (w == null) return '-';
    final d = w.toDouble();
    final isIntLike = d == d.roundToDouble();
    return isIntLike ? '${d.toStringAsFixed(0)} kg' : '${d.toStringAsFixed(1)} kg';
  }

  Widget _roundIconButton({
    IconData? icon,
    String? asset,
    Color foreground = const Color(0xFF222222),
    required String tooltip,
    required VoidCallback? onTap,
    double size = 20,
    double pad = 6,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: asset != null
                ? Image.asset(asset, width: size, height: size)
                : Icon(icon, size: size, color: foreground),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {required double f, required PetProfileCardStyle style}) {
    if (style == PetProfileCardStyle.gradientBorder) {
      // 라벨-값 줄: 외곽 그라데 라벤더, 내부 화이트
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 5 * f),
        child: Container(
          padding: EdgeInsets.all(1.2 * f),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_lav, _lav], // 외곽선 톤을 #F7F2FA로 통일
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14 * f),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10 * f, horizontal: 14 * f),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12 * f),
            ),
            child: _rowContent(label, value, f),
          ),
        ),
      );
    } else {
      // 뉴모피즘 스타일 유지 (연한 보라 톤)
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 5 * f),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12 * f, horizontal: 14 * f),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EEFF),
            borderRadius: BorderRadius.circular(14 * f),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 6)),
              BoxShadow(color: Colors.white, blurRadius: 8, offset: Offset(-4, -4)),
            ],
          ),
          child: _rowContent(label, value, f),
        ),
      );
    }
  }

  Row _rowContent(String label, String value, double f) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppFont(' ', size: 0),
        AppFont(label, size: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0B0B0B)),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: AppFont(value, size: 17, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
          ),
        ),
      ],
    );
  }

  static String _genderEmoji(String? g) {
    if (g == null || g.isEmpty) return '-';
    final u = g.toUpperCase();
    if (u == 'M') return '♂️';
    if (u == 'F') return '♀️';
    return '-';
  }

  static String _mapNeutered(bool? n) {
    if (n == null) return '-';
    return n ? '예' : '아니오';
  }

  Future<void> _deletePet(BuildContext context, int petId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('지금까지의 기록이 모두 삭제됩니다.\n정말 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final rsp = await AuthApi.client.delete('/pets/$petId', options: Options(validateStatus: (_) => true));
      if (rsp.statusCode == 200 || rsp.statusCode == 204 || rsp.statusCode == 404) {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await context.read<PetIdStore>().initFromUserMeAndPets(baseUrl: Env.baseUrl);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
          );
        }
      } else {
        String msg = '삭제 실패 (${rsp.statusCode})';
        try {
          final b = rsp.data is Map<String, dynamic> ? rsp.data as Map<String, dynamic> : jsonDecode('${rsp.data}');
          final serverMsg = (b['message'] ?? b['error'] ?? b['code'])?.toString();
          if (serverMsg != null && serverMsg.isNotEmpty) msg = '$msg - $serverMsg';
        } catch (_) {}
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 중 오류: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }
}
