import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'showcase_keys.dart';
import '../../../jobs/presentation/screens/job_listings_screen.dart';
import '../../../tests/presentation/screens/mock_test_details_screen.dart';
import '../../../resume/presentation/screens/chat_resume_screen.dart';
import '../../../games/presentation/screens/brain_games_screen.dart';

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final screens = [
      const HomeScreen(),
      const JobListingsScreen(),
      const MockTestDetailsScreen(),
      const ChatResumeScreen(),
      const BrainGamesScreen(),
    ];

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ref.read(navigationIndexProvider.notifier).setIndex(0);
      },
      child: ShowCaseWidget(
        builder: (context) => Scaffold(
          body: IndexedStack(
            index: currentIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  ref.read(navigationIndexProvider.notifier).setIndex(index);
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.white,
                selectedItemColor: AppColors.primaryBrand,
                unselectedItemColor: AppColors.secondaryText,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                elevation: 8,
                items: [
                  const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                    icon: Showcase(
                      key: ShowcaseKeys.tabJobs,
                      description: 'Browse and apply for jobs here.',
                      child: const Icon(Icons.work),
                    ),
                    label: 'Jobs',
                  ),
                  BottomNavigationBarItem(
                    icon: Showcase(
                      key: ShowcaseKeys.tabTests,
                      description: 'Take tests to improve your skills.',
                      child: const Icon(Icons.assignment),
                    ),
                    label: 'Tests',
                  ),
                  BottomNavigationBarItem(
                    icon: Showcase(
                      key: ShowcaseKeys.tabResume,
                      description: 'Build and manage your professional resume.',
                      child: const Icon(Icons.description),
                    ),
                    label: 'Resume',
                  ),
                  BottomNavigationBarItem(
                    icon: Showcase(
                      key: ShowcaseKeys.tabGames,
                      description: 'Play brain games to sharpen your mind.',
                      child: const Icon(Icons.extension),
                    ),
                    label: 'Games',
                  ),
                ],
              ),
          ),
        ),
    );
  }
}
