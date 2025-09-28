import 'package:flutter/material.dart';

class MediaPickerSheet extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onTakePicture;

  const MediaPickerSheet({
    super.key,
    required this.onPickImage,
    required this.onTakePicture,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('갤러리에서 선택'),
            onTap: () {
              Navigator.pop(context);
              onPickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('사진 촬영'),
            onTap: () {
              Navigator.pop(context);
              onTakePicture();
            },
          ),
        ],
      ),
    );
  }
}
