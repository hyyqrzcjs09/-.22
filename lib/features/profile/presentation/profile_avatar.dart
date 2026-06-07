import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.imageBase64,
    super.key,
    this.radius = 30,
  });

  final String? imageBase64;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = _decodeImage(imageBase64);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      backgroundImage: image == null ? null : MemoryImage(image),
      child: image == null ? Icon(Icons.person, size: radius * 1.12) : null,
    );
  }
}

Uint8List? _decodeImage(String? imageBase64) {
  if (imageBase64 == null || imageBase64.isEmpty) {
    return null;
  }

  try {
    return base64Decode(imageBase64);
  } on FormatException {
    return null;
  }
}
