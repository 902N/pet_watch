
import 'package:flutter/material.dart';

class AppFont extends StatelessWidget {
  final String text;
  final FontWeight? fontWeight;
  final double? size;
  final Color? color;

  const AppFont(
    this.text, {
    super.key,
    this.fontWeight,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: fontWeight,
        fontSize: size,
        color: color,
      ),
    );
  }
}
