import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import 'sudoku_screen.dart';

/// Games tab.
class BrainGamesScreen extends StatelessWidget {
  const BrainGamesScreen({super.key});

  void _openSudoku(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const SudokuScreen()));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Brain Games', style: AppText.screenTitle),
              SizedBox(height: 2),
              Text('Sharpen focus, memory and logic', style: AppText.label),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _hero(context),
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 10, left: 4),
              child: Text('Games', style: AppText.sectionTitle),
            ),
            _GameCard(
              icon: Icons.grid_on_rounded,
              title: 'Sudoku',
              subtitle: '6×6 number puzzle',
              chips: const [('Easy', Color(0xFF059669)), ('~5 min', AppColors.secondaryText)],
              onTap: () => _openSudoku(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppUi.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Challenge your mind', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('A few minutes of puzzles a day keeps your problem-solving sharp for tests and interviews.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _openSudoku(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: AppUi.ink, size: 20),
                        SizedBox(width: 4),
                        Text('Play Sudoku', style: TextStyle(color: AppUi.ink, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, Color)> chips;
  final VoidCallback onTap;

  const _GameCard({required this.icon, required this.title, required this.subtitle, required this.chips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppUi.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(gradient: AppUi.accentGradient, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.cardTitle),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.label),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: chips
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: c.$2.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(c.$1, style: AppText.badge.copyWith(color: c.$2)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
