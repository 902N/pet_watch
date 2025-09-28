import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AutoSizeImage extends StatefulWidget {
  final String? imageUrl;
  final File? file;
  final double borderRadius;
  final double maxHeight;
  final VoidCallback? onTap;

  const AutoSizeImage({
    super.key,
    this.imageUrl,
    this.file,
    this.borderRadius = 12,
    this.maxHeight = 360,
    this.onTap,
  });

  @override
  State<AutoSizeImage> createState() => _AutoSizeImageState();
}

class _AutoSizeImageState extends State<AutoSizeImage> {
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolveAspect();
  }

  @override
  void didUpdateWidget(covariant AutoSizeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.file?.path != widget.file?.path) {
      _aspect = null;
      _resolveAspect();
    }
  }

  Future<void> _resolveAspect() async {
    try {
      if (widget.file != null) {
        final bytes = await widget.file!.readAsBytes();
        final img = await _decode(bytes);
        if (mounted) setState(() => _aspect = img.width / img.height.toDouble());
        return;
      }
      if ((widget.imageUrl ?? '').isNotEmpty) {
        final provider = NetworkImage(widget.imageUrl!);
        final stream = provider.resolve(const ImageConfiguration());
        final c = Completer<void>();
        late ImageStreamListener l;
        l = ImageStreamListener((info, _) {
          _aspect = info.image.width / info.image.height.toDouble();
          c.complete();
          stream.removeListener(l);
          if (mounted) setState(() {});
        }, onError: (_, __) {
          c.complete();
          stream.removeListener(l);
        });
        stream.addListener(l);
        await c.future;
      }
    } catch (_) {}
  }

  Future<ui.Image> _decode(Uint8List bytes) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) => c.complete(img));
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    final has = widget.file != null || (widget.imageUrl ?? '').isNotEmpty;
    if (!has) return const SizedBox.shrink();

    final img = widget.file != null
        ? Image.file(widget.file!, fit: BoxFit.contain)
        : Image.network(widget.imageUrl!, fit: BoxFit.contain);

    final body = _aspect == null
        ? const SizedBox(
      height: 180,
      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
    )
        : LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final a = _aspect! <= 0 ? 1.0 : _aspect!;
      final h = (w / a).clamp(0, widget.maxHeight).toDouble();
      return SizedBox(
        width: w,
        height: h,
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(width: w, child: img),
        ),
      );
    });

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: double.infinity,
          color: const Color(0xFFF5F7FA),
          child: body,
        ),
      ),
    );
  }
}
