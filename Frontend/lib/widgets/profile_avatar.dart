import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A circular profile avatar. Shows the device-stored photo (a base64 data
/// URI) when available, otherwise the user's initials on a tinted circle.
class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? dataUri;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.dataUri,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(dataUri);
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover, width: size, height: size)
          : Text(
              _initials(name),
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: size * 0.36,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  static Uint8List? _decode(String? dataUri) {
    if (dataUri == null || dataUri.isEmpty) return null;
    final comma = dataUri.indexOf(',');
    final b64 = comma >= 0 ? dataUri.substring(comma + 1) : dataUri;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
