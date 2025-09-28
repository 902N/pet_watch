import 'package:flutter/material.dart';
import 'package:APP/login/widgets/white_decoration.dart';

class RowGenderNeuter extends StatelessWidget {
  final String gender; // 'M' | 'F'
  final bool neutered;
  final ValueChanged<String?> onGender;
  final ValueChanged<bool> onNeutered;
  final InputDecoration Function(String, {String? hint}) decoration;

  const RowGenderNeuter({
    super.key,
    required this.gender,
    required this.neutered,
    required this.onGender,
    required this.onNeutered,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: gender.toUpperCase(),
              isExpanded: true,
              decoration: decoration('성별'),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('남')),
                DropdownMenuItem(value: 'F', child: Text('여')),
              ],
              onChanged: onGender,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InputDecorator(
              decoration: decoration('중성화'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('중성화'),
                  Switch.adaptive(
                    value: neutered,
                    onChanged: onNeutered,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
