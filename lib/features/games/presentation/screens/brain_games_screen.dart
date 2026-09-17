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
            
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SudokuScreen()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrand.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.grid_on, size: 32, color: AppColors.primaryBrand)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Sudoku', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                          SizedBox(height: 4),
                          Text('Classic number puzzle', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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