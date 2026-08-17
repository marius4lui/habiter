import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../domain/update_models.dart';

final class VerifiedReleaseImage extends StatefulWidget {
  const VerifiedReleaseImage({
    required this.media,
    required this.fallback,
    super.key,
  });

  final ReleaseMedia? media;
  final Widget fallback;

  @override
  State<VerifiedReleaseImage> createState() => _VerifiedReleaseImageState();
}

class _VerifiedReleaseImageState extends State<VerifiedReleaseImage> {
  late Future<Uint8List?> _image;

  @override
  void initState() {
    super.initState();
    _image = _load();
  }

  @override
  void didUpdateWidget(covariant VerifiedReleaseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media?.url != widget.media?.url) _image = _load();
  }

  Future<Uint8List?> _load() async {
    final media = widget.media;
    if (media == null || media.size > 12 * 1024 * 1024) return null;
    try {
      final response = await http
          .get(media.url)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 ||
          response.bodyBytes.length != media.size) {
        return null;
      }
      if (sha256.convert(response.bodyBytes).toString() != media.sha256) {
        return null;
      }
      return response.bodyBytes;
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _image,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) return widget.fallback;
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    },
  );
}
