import 'package:flutter/material.dart';

class Accordion extends StatelessWidget {
  final String title;
  const Accordion({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          children: const [
            ListTile(title: Text('임시 항목 1')),
            ListTile(title: Text('임시 항목 2')),
          ],
        ),
      ),
    );
  }
}
