import 'package:flutter/material.dart';

class SettingsRow extends StatelessWidget {
  final Widget left;
  final Widget? right;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.left,
    this.right,
    this.onTap,
  });

  static const _height = 52.0;
  static const _pad = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    return Material(                           // ← Material 추가
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _height),
          child: Container(
            width: double.infinity,           // ← 히트영역 전체폭
            padding: _pad,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 16),
                    child: left,
                  ),
                ),
                if (right != null) right!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
