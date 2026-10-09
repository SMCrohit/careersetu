import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/professional_model.dart';
import 'professional_avatar.dart';

/// Small rounded label used across the professionals screens.
class ProChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const ProChip({super.key, required this.label, this.icon, this.color = AppColors.primaryBrand});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: AppText.badge.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// "★ 4.6 (12)".
class RatingLabel extends StatelessWidget {
  final Professional professional;
  final double size;

  const RatingLabel({super.key, required this.professional, this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 3, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 2),
        Text(professional.ratingLabel, style: AppText.value.copyWith(fontSize: size)),
        if (professional.reviews > 0) Text(' (${professional.reviews})', style: AppText.label.copyWith(fontSize: size - 1)),
      ],
    );
  }
}

IconData modeIcon(String mode) => switch (mode.toLowerCase()) {
      'online' => Icons.videocam_outlined,
      'phone' => Icons.call_outlined,
      _ => Icons.location_on_outlined,
    };

/// A professional in the listing.
class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onTap;

  const ProfessionalCard({super.key, required this.professional, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = professional;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
        border: p.isFeatured ? Border.all(color: const Color(0xFFBAE6FD)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfessionalAvatar(professional: p, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.cardTitle)),
                              if (p.isFeatured) const ProChip(label: 'Featured', icon: Icons.star_rounded, color: Color(0xFF0284C7)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(p.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle.copyWith(fontSize: 13)),
                          if (p.qualification != null)
                            Text(p.qualification!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RatingLabel(professional: p, size: 12),
                              _meta(Icons.workspace_premium_outlined, p.experienceLabel),
                              if (p.locationCity.isNotEmpty) _meta(Icons.location_on_outlined, p.locationCity),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (p.consultationMode.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.consultationMode.map((m) => ProChip(label: m, icon: modeIcon(m), color: AppColors.secondaryText)).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nextAvailable != null ? 'Next available' : 'Availability', style: AppText.label),
                          Text(
                            p.nextAvailable?.label ?? 'No open slots soon',
                            style: AppText.value.copyWith(
                              fontSize: 13,
                              color: p.nextAvailable != null ? const Color(0xFF059669) : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(p.feeLabel, style: AppText.cardTitle.copyWith(fontSize: 16)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: AppUi.accentGradient, borderRadius: BorderRadius.circular(20)),
                      child: Text('Book', style: AppText.badge.copyWith(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryText),
          const SizedBox(width: 3),
          Text(text, style: AppText.label),
        ],
      );
}

/// Grey placeholder while professionals load.
class ProfessionalCardSkeleton extends StatelessWidget {
  const ProfessionalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, [double r = 6]) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(r)));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            bar(56, 56, 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(150, 14), const SizedBox(height: 8), bar(110, 12), const SizedBox(height: 8), bar(170, 12)]),
          ]),
          const SizedBox(height: 16),
          Row(children: [bar(120, 28), const Spacer(), bar(70, 32, 16)]),
        ],
      ),
    );
  }
}
