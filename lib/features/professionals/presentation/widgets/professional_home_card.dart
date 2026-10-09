import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/professional_model.dart';
import 'professional_avatar.dart';
import 'professional_card.dart';

/// Compact card for the Home sections (horizontal list, 230 tall).
class ProfessionalHomeCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onTap;

  const ProfessionalHomeCard({super.key, required this.professional, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = professional;
    return Container(
      width: 148,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: AppUi.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            child: Column(
              children: [
                ProfessionalAvatar(professional: p, size: 64),
                const SizedBox(height: 10),
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.value.copyWith(fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  p.specialty.isNotEmpty ? p.specialty : p.profession,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.label,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RatingLabel(professional: p, size: 12),
                    Text('  ·  ${p.feeLabel}', style: AppText.label.copyWith(color: AppColors.primaryText)),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: AppUi.iconTile, borderRadius: BorderRadius.circular(20)),
                  child: Text('Book now', textAlign: TextAlign.center, style: AppText.badge.copyWith(color: const Color(0xFF0369A1), fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in a Home section when nothing is featured yet.
class ExploreProfessionalsCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ExploreProfessionalsCard({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(gradient: AppUi.heroGradient, borderRadius: BorderRadius.circular(16), boxShadow: AppUi.cardShadow),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 34),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: AppText.value.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text('See everyone', style: AppText.label.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
