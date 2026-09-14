import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'sudoku_screen.dart';

class BrainGamesScreen extends StatelessWidget {
  const BrainGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // As requested: all background of Brain Game is white
      appBar: AppBar(
        title: const Text('Brain Games', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Challenge your mind',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Play quick brain games to improve focus, memory, and problem-solving skills.',
              style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 24),
            
            // Sudoku Card hidden for now
            
            // Coming Soon Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.extension_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('More coming soon...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
                  const SizedBox(height: 4),
                  Text('We are adding more games to challenge your brain!', style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}