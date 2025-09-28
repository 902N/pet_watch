import 'package:flutter/material.dart';
import 'screens/walk_home.dart';

void main() => runApp(const WalkApp());

class WalkApp extends StatelessWidget {
  const WalkApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: WalkHome());
}
