import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/professional_model.dart';

/// Photo or initials, with a gradient ring for featured professionals.
class ProfessionalAvatar extends StatelessWidget {
  final Professional professional;
  final double size;
  final bool showRing;

  const ProfessionalAvatar({super.key, required this.professional, this.size = 56, this.showRing = true});

  @override
  Widget build(BuildContext context) {
    final ring = showRing && professional.isFeatured;
    final inner = ClipOval(
      child: SizedBox(width: size, height: size, child: _image()),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: inner,
      ),
    );
  }

  Widget _image() {
    final url = professional.photoUrl;
    final fallback = _initials();
    if (url == null) return fallback;
    if (url.startsWith('data:image')) {
      try {
        var b64 = url.split(',').last.replaceAll(RegExp(r'\s+'), '');
        if (b64.length % 4 != 0) b64 += '=' * (4 - b64.length % 4);
        return Image.memory(base64Decode(b64), fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
      } catch (_) {
        return fallback;
      }
    }
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }

  Widget _initials() {
    return Container(
      decoration: const BoxDecoration(color: AppUi.iconTile),
      alignment: Alignment.center,
      child: Text(
        professional.initials,
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
      ),
    );
  }
}
