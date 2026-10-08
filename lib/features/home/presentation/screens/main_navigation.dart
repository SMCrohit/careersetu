import 'package:flutter/material.dart';
import '../widgets/custom_curved_nav_bar/curved_navigation_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/widgets/custom_showcase.dart';
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
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
              child: CurvedNavigationBar(
              height: 60.0,
              backgroundColor: Colors.transparent,
              color: Colors.white,
              buttonGradient: const LinearGradient(
                colors: [Color(0xFF0ea5e9), Color(0xFF3b82f6)],
              ),
              animationDuration: const Duration(milliseconds: 300),
              onTap: (index) {
                    ref.read(navigationIndexProvider.notifier).setIndex(index);
                  },
                  items: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, size: 28, color: currentIndex == 0 ? Colors.white : Colors.grey),
                        if (currentIndex != 0) const Text('Home', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ]
                    ),
                    CustomShowcase(
                      showcaseKey: ShowcaseKeys.tabJobs,
                      description: 'Access your job applications here.',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work, size: 28, color: currentIndex == 1 ? Colors.white : Colors.grey),
                          if (currentIndex != 1) const Text('Jobs', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ]
                      ),
                    ),
                    CustomShowcase(
                      showcaseKey: ShowcaseKeys.tabTests,
                      description: 'Take tests to improve your skills.',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment, size: 28, color: currentIndex == 2 ? Colors.white : Colors.grey),
                          if (currentIndex != 2) const Text('Tests', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ]
                      ),
                    ),
                    CustomShowcase(
                      showcaseKey: ShowcaseKeys.tabResume,
                      description: 'Build and manage your professional resume.',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description, size: 28, color: currentIndex == 3 ? Colors.white : Colors.grey),
                          if (currentIndex != 3) const Text('Resume', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ]
                      ),
                    ),
                    CustomShowcase(
                      showcaseKey: ShowcaseKeys.tabGames,
                      description: 'Play brain games to sharpen your mind.',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.extension, size: 28, color: currentIndex == 4 ? Colors.white : Colors.grey),
                          if (currentIndex != 4) const Text('Games', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ]
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
    ); // close PopScope
  }
}
